#!/bin/bash

# Instalar msmtp y otras dependencias necesarias
sudo apt update
sudo apt install -y msmtp cron

# Solicitar el correo y la contraseña
read -p "Introduce tu correo electrónico: " email
read -s -p "Introduce tu contraseña de correo: " password
echo

# Solicitar la ubicación donde se encuentra el script monitoriza.sh
/etc/monitoriza.sh script_path

# Asegurarse de que el script monitoriza.sh tenga permisos de ejecución
chmod +x "$script_path"

# Crear una entrada en el crontab del sistema para ejecutar el script cada 5 minutos
# La línea que añadimos en el crontab debe incluir el nombre del usuario actual
user=$(whoami)
echo "*/5 * * * * $user $script_path" | sudo tee -a /etc/crontab > /dev/null

# Crear un archivo de servicio systemd para el script
cat <<EOL | sudo tee /etc/systemd/system/monitoriza.service > /dev/null
[Unit]
Description=Servicio de Monitorización del Sistema
After=network.target

[Service]
ExecStart=$script_path
Restart=always
User=$user
Group=$user

[Install]
WantedBy=multi-user.target
EOL

# Recargar los servicios de systemd y habilitar el nuevo servicio
sudo systemctl daemon-reload
sudo systemctl enable monitoriza.service
sudo systemctl start monitoriza.service

# Crear la configuración de msmtp
echo "Configurando msmtp para Gmail..."

cat <<EOL | sudo tee /etc/msmtprc > /dev/null
account default
host smtp.gmail.com
port 587
from $email
user $email
password $password
tls on
tls_starttls on
auth on
logfile /var/log/msmtp.log
EOL

# Enviar un correo de prueba
echo -e "Subject: prueba\n\nHola" | msmtp $email

echo "Correo de prueba enviado a $email."
