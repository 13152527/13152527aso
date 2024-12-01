#!/bin/bash

# Instalar msmtp
sudo apt update
sudo apt install -y msmtp

# Solicitar el correo y la contraseña
read -p "Introduce tu correo electrónico: " email
read -s -p "Introduce tu contraseña de correo: " password
echo

# Crear una entrada en el crontab del sistema para ejecutar el script cada 5 minutos como root
echo "*/5 * * * * root /etc/monitoriza.sh" | sudo tee -a /etc/crontab > /dev/null

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

# Asegurarse de que el archivo de configuración tenga los permisos correctos
sudo chmod 600 /etc/msmtprc

# Crear el servicio systemd para la supervisión (ejecución continua)
SERVICE_FILE="/etc/systemd/system/monitorizacion.service"

echo "Creando el servicio systemd para la supervisión (ejecución continua)..."
sudo tee "$SERVICE_FILE" > /dev/null <<EOL
[Unit]
Description=Servicio de supervisión del sistema
After=network.target

[Service]
ExecStart=/bin/bash /etc/monitoriza.sh
Restart=always
RestartSec=5s
Type=simple

[Install]
WantedBy=multi-user.target
EOL

# Recargar los servicios de systemd, habilitar e iniciar el servicio
echo "Recargando systemd y habilitando el servicio de monitoreo..."
sudo systemctl daemon-reload
if sudo systemctl enable monitorizacion; then
  echo "Servicio 'monitorizacion' habilitado con éxito."
else
  echo "Error al habilitar el servicio 'monitorizacion'."
  exit 1
fi

if sudo systemctl start monitorizacion; then
  echo "Servicio 'monitorizacion' iniciado con éxito."
else
  echo "Error al iniciar el servicio 'monitorizacion'."
  exit 1
fi

# Enviar un correo de prueba
echo -e "Subject: prueba\n\nHola" | msmtp $email

echo "Correo de prueba enviado a $email."
