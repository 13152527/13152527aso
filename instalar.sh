#!/bin/bash

# Actualizar paquetes e instalar msmtp
sudo apt update && sudo apt install -y msmtp || { printf "Error al instalar msmtp\n" >&2; exit 1; }

# Solicitar correo electrónico y contraseña
read -p "Introduce tu correo electrónico: " email
while [[ ! "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; do
    printf "Correo inválido. Inténtalo nuevamente.\n"
    read -p "Introduce tu correo electrónico: " email
done

read -s -p "Introduce tu contraseña de correo: " password
printf "\n"

# Validar correo y contraseña
if [[ -z "$email" || -z "$password" ]]; then
    printf "El correo y la contraseña no pueden estar vacíos.\n" >&2
    exit 1
fi

# Crear y configurar msmtp
sudo tee /etc/msmtprc > /dev/null <<EOL
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

sudo chmod 600 /etc/msmtprc || { printf "Error al configurar permisos de /etc/msmtprc\n" >&2; exit 1; }

# Configurar el servicio systemd
sudo tee /etc/systemd/system/monitorizacion.service > /dev/null <<EOL
[Unit]
Description=Servicio de supervisión del sistema
After=network.target

[Service]
ExecStart=/bin/bash /etc/monitoriza.sh
Type=oneshot
EOL

sudo tee /etc/systemd/system/monitorizacion.timer > /dev/null <<EOL
[Unit]
Description=Temporizador para el servicio de supervisión cada 15 minutos

[Timer]
OnBootSec=15min
OnUnitActiveSec=15min

[Install]
WantedBy=timers.target
EOL

sudo systemctl daemon-reload || { printf "Error al recargar systemd\n" >&2; exit 1; }
sudo systemctl enable monitorizacion.timer || { printf "Error al habilitar el temporizador\n" >&2; exit 1; }
sudo systemctl start monitorizacion.timer || { printf "Error al iniciar el temporizador\n" >&2; exit 1; }

# Crear entrada en crontab
if ! grep -q "/etc/monitoriza.sh" /etc/crontab; then
    echo "*/5 * * * * root /bin/bash /etc/monitoriza.sh" | sudo tee -a /etc/crontab > /dev/null || { printf "Error al configurar crontab\n" >&2; exit 1; }
fi

# Enviar un correo de prueba
printf "Enviando correo de prueba...\n"
if ! echo -e "Subject: prueba\n\nHola" | msmtp "$email"; then
    printf "Error al enviar el correo de prueba\n" >&2
    exit 1
fi

printf "Configuración completa y correo de prueba enviado a %s\n" "$email"
