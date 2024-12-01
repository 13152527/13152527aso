#!/bin/bash

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # Sin color

# Archivo de log
LOG_FILE="monitorizacion.log"

# Obtener la dirección de correo y la contraseña desde /etc/msmtprc
recipient_email=$(grep -i "from" /etc/msmtprc | awk '{print $2}')
user_email=$(grep -i "user" /etc/msmtprc | awk '{print $2}')
user_password=$(grep -i "password" /etc/msmtprc | awk '{print $2}')

# Comprobamos si se obtuvo el correo y la contraseña correctamente
if [ -z "$recipient_email" ] || [ -z "$user_password" ]; then
    echo -e "${RED}No se encontró el correo electrónico o la contraseña en la configuración de msmtp. Asegúrate de que el archivo /etc/msmtprc esté correctamente configurado.${NC}"
    exit 1
fi

# Inicio del script
echo -e "${GREEN}===== Inicio de Monitorización =====${NC}" | tee -a $LOG_FILE

# Obtener el uso de CPU
CPU_USAGE=$(mpstat | awk '/all/ {print "CPU Load: " $3 "% idle"}')

# Obtener el uso de RAM
RAM_USAGE=$(free -h | awk '/Mem/ {print "Total Memory: " $2 "\nUsed: " $3 "\nFree: " $4}')
SWAP_USAGE=$(free -h | awk '/Swap/ {print "Swap - Total: " $2 ", Used: " $3 ", Free: " $4}')

# Obtener los procesos que más RAM consumen
RAM_PROCESSES=$(ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6)

# Obtener los procesos que más CPU consumen
CPU_PROCESSES=$(ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6)

# Imprimir la información de uso de CPU, RAM y procesos, y también guardarla en el log
echo -e "${YELLOW}>> Uso de CPU:${NC}" | tee -a $LOG_FILE
echo -e "$CPU_USAGE" | tee -a $LOG_FILE

echo -e "${YELLOW}>> Uso de RAM:${NC}" | tee -a $LOG_FILE
echo -e "$RAM_USAGE\n$SWAP_USAGE" | tee -a $LOG_FILE

echo -e "${YELLOW}>> Procesos que más RAM están consumiendo:${NC}" | tee -a $LOG_FILE
echo -e "$RAM_PROCESSES" | tee -a $LOG_FILE

echo -e "${YELLOW}>> Procesos que más CPU están consumiendo:${NC}" | tee -a $LOG_FILE
echo -e "$CPU_PROCESSES" | tee -a $LOG_FILE

# Sección de errores del sistema
echo -e "${YELLOW}\n>> Errores en System Logs:${NC}" | tee -a $LOG_FILE

echo -e "${RED}Errores Críticos (Emergencia y Alertas):${NC}" | tee -a $LOG_FILE
journalctl -p 0..1 -xb | tail -n 10 | tee -a $LOG_FILE

echo -e "${RED}Errores Importantes (Errores y Advertencias):${NC}" | tee -a $LOG_FILE
journalctl -p 2..4 -xb | tail -n 10 | tee -a $LOG_FILE

echo -e "${BLUE}Eventos Informativos (Notificaciones y Debug):${NC}" | tee -a $LOG_FILE
journalctl -p 5..7 -xb | tail -n 10 | tee -a $LOG_FILE

# Componer el contenido para el correo
EMAIL_BODY="===== Reporte de Monitorización del Sistema =====\n\n"
EMAIL_BODY+=">> Uso de CPU:\n$CPU_USAGE\n\n"
EMAIL_BODY+=">> Uso de RAM:\n$RAM_USAGE\n$SWAP_USAGE\n\n"
EMAIL_BODY+=">> Procesos que más RAM están consumiendo:\n$RAM_PROCESSES\n\n"
EMAIL_BODY+=">> Procesos que más CPU están consumiendo:\n$CPU_PROCESSES\n\n"
EMAIL_BODY+=">> Errores Críticos (Emergencia y Alertas):\n$(journalctl -p 0..1 -xb | tail -n 10)\n\n"
EMAIL_BODY+=">> Errores Importantes (Errores y Advertencias):\n$(journalctl -p 2..4 -xb | tail -n 10)\n\n"
EMAIL_BODY+=">> Eventos Informativos (Notificaciones y Debug):\n$(journalctl -p 5..7 -xb | tail -n 10)\n"

# Enviar correo con la información relevante
echo -e "Subject: Reporte de Monitorización del Sistema\n\n$EMAIL_BODY" | msmtp $recipient_email

echo -e "${GREEN}Reporte enviado a $recipient_email${NC}" | tee -a $LOG_FILE

# Fin del script
echo -e "${GREEN}===== Monitorización Completa =====${NC}" | tee -a $LOG_FILE
echo "$(date '+%Y-%m-%d %H:%M:%S') - Monitorización completa" >> $LOG_FILE
