#!/bin/bash

# Instalar msmtp
sudo apt update
sudo apt install -y msmtp

# Solicitar el correo y la contraseña
read -p "Introduce tu correo electrónico: " email
read -s -p "Introduce tu contraseña de correo: " password
echo

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
