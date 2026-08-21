#!/bin/bash
set -e

echo "=== Starting user_data script at $(date) ==="

# Обновляем пакеты
apt-get update -y

# Устанавливаем LAMP стек с автоматическим подтверждением
DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 mysql-server php php-mysql php-gd php-curl

# Запускаем Apache
systemctl start apache2
systemctl enable apache2

# Создаем директорию для сайта
mkdir -p /var/www/html

# Создаем веб-страницу
cat > /var/www/html/index.html << 'EOL'
<!DOCTYPE html>
<html>
<head>
    <title>LAMP Stack with Image from Object Storage</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            padding: 50px;
            background-color: #f0f0f0;
        }
        img {
            max-width: 500px;
            border-radius: 10px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.2);
        }
        h1 {
            color: #333;
        }
        .container {
            background: white;
            padding: 20px;
            border-radius: 10px;
            max-width: 600px;
            margin: 0 auto;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 LAMP Stack Instance</h1>
        <p>Instance: $(hostname)</p>
        <p>IP Address: $(hostname -I | awk '{print $1}')</p>
        <h2>Image from Object Storage:</h2>
        <img src="${image_url}" alt="Image from Object Storage">
    </div>
</body>
</html>
EOL

# Настраиваем права
chown -R www-data:www-data /var/www/html

# Перезапускаем Apache
systemctl restart apache2

echo "=== user_data script finished at $(date) ==="
