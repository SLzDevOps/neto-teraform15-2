# instance_group.tf

# 1. Получение актуального образа LAMP
data "yandex_compute_image" "lamp" {
  family = "lamp"
}

# 2. Создание Instance Group
resource "yandex_compute_instance_group" "lamp_group" {
  name               = "lamp-instance-group"
  folder_id          = var.yc_folder_id
  service_account_id = data.yandex_iam_service_account.sa_storage.id

  instance_template {
    platform_id = "standard-v1"
    
    # Человекочитаемые имена для ВМ в группе
    name = "lamp-{instance.index}"

    resources {
      cores         = 2
      memory        = 2
      core_fraction = 20  # Экономия!
    }

    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = data.yandex_compute_image.lamp.image_id
        size     = 20
      }
    }

    network_interface {
      subnet_ids = [yandex_vpc_subnet.public.id]
      nat        = true
    }

    metadata = {
      user-data = templatefile("${path.module}/user_data.sh", {
        image_url = "https://storage.yandexcloud.net/${yandex_storage_bucket.images.bucket}/${yandex_storage_object.image.key}"
      })
      ssh-keys = "ubuntu:${file(var.ssh_public_key)}"
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = [var.zone]
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 1
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10

    http_options {
      port = 80
      path = "/"
    }
  }

  load_balancer {
    target_group_name = "lamp-target-group"
  }

  depends_on = [
    yandex_storage_bucket.images,
    yandex_storage_object.image
  ]
}

# 3. Создание сетевого балансировщика
resource "yandex_lb_network_load_balancer" "lamp_lb" {
  name = "lamp-network-load-balancer"

  listener {
    name = "http-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.lamp_group.load_balancer[0].target_group_id

    healthcheck {
      name = "http-healthcheck"
      timeout = 5
      interval = 10
      healthy_threshold = 2
      unhealthy_threshold = 2
      
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}

# 4. Получение IP балансировщика
output "lb_ip" {
  value = one([
    for listener in yandex_lb_network_load_balancer.lamp_lb.listener :
    one(listener.external_address_spec).address
  ])
}

# 5. Получение информации о группе
output "instance_group_instances" {
  value = yandex_compute_instance_group.lamp_group.instances[*].name
}
