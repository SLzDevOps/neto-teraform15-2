# 1. Используем сервисный аккаунт из key.json через data
data "yandex_iam_service_account" "sa_storage" {
  service_account_id = "aje8g2d70g62bs8f4ebi"  # ID из вашего key.json
}

# 2. Создаем статический ключ для сервисного аккаунта
resource "yandex_iam_service_account_static_access_key" "sa_storage_key" {
  service_account_id = data.yandex_iam_service_account.sa_storage.id
}

# 3. Создание бакета Object Storage
resource "yandex_storage_bucket" "images" {
  bucket     = var.bucket_name
  access_key = yandex_iam_service_account_static_access_key.sa_storage_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa_storage_key.secret_key

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

# 4. Делаем бакет публичным через grant
resource "yandex_storage_bucket_grant" "public_read" {
  bucket = yandex_storage_bucket.images.bucket

  grant {
    permissions = ["READ"]
    type        = "Group"
    uri         = "http://acs.amazonaws.com/groups/global/AllUsers"
  }
}

# 5. Загрузка картинки в бакет
resource "yandex_storage_object" "image" {
  access_key = yandex_iam_service_account_static_access_key.sa_storage_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa_storage_key.secret_key
  bucket     = yandex_storage_bucket.images.bucket
  key        = "example-image.jpg"
  source     = var.image_path

  depends_on = [
    yandex_storage_bucket.images,
    yandex_storage_bucket_grant.public_read
  ]
}

# 6. Получение URL картинки
output "image_url" {
  value = "https://storage.yandexcloud.net/${yandex_storage_bucket.images.bucket}/${yandex_storage_object.image.key}"
}
