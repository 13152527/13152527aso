#!/bin/bash

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # Sin color

# Archivo de log
LOG_FILE="/var/log/monitorizacion.log"

# Crear el archivo de log si no existe y establecer permisos adecuados
if [[ ! -f "$LOG_FILE" ]]; then
    sudo touch "$LOG_FILE" || { printf "${RED}Error al crear el archivo de log en $LOG_FILE.${NC}\n" >&2; exit 1; }
    sudo chmod 640 "$LOG_FILE" || { printf "${RED}Error al establecer permisos del archivo de log.${NC}\n" >&2; exit 1; }
fi

# Redirigir stdout y stderr al log (mantener la salida a consola también)
exec > >(tee -a "$LOG_FILE") 2>&1

# Obtener la dirección de correo y la contraseña desde /etc/msmtprc
recipient_email=$(grep -i "^from" /etc/msmtprc | awk '{print $2}')
user_email=$(grep -i "^user" /etc/msmtprc | awk '{print $2}')
user_password=$(grep -i "^password" /etc/msmtprc | awk '{print $2}')

# Comprobamos si se obtuvo el correo y la contraseña correctamente
if [[ -z "$recipient_email" || -z "$user_password" ]]; then
    printf "${RED}No se encontró el correo electrónico o la contraseña en la configuración de msmtp. Asegúrate de que el archivo /etc/msmtprc esté correctamente configurado.${NC}\n"
    exit 1
fi

# Inicio del script
printf "${GREEN}===== Inicio de Monitorización =====${NC}\n"

# Obtener el uso de CPU
cpu_usage=$(mpstat 1 1 | awk '/all/ {print "CPU Load: " 100 - $12 "% used"}')
if [[ -z "$cpu_usage" ]]; then
    printf "${RED}Error al obtener el uso de CPU.${NC}\n"
    cpu_usage="No disponible"
fi

# Obtener el uso de RAM
ram_usage=$(free -h | awk '/Mem/ {print "Total Memory: " $2 "\nUsed: " $3 "\nFree: " $4}')
swap_usage=$(free -h | awk '/Swap/ {print "Swap - Total: " $2 ", Used: " $3 ", Free: " $4}')
if [[ -z "$ram_usage" || -z "$swap_usage" ]]; then
    printf "${RED}Error al obtener el uso de RAM.${NC}\n"
    ram_usage="No disponible"
    swap_usage="No disponible"
fi

# Obtener los procesos que más RAM consumen
ram_processes=$(ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6)
if [[ -z "$ram_processes" ]]; then
    printf "${RED}Error al obtener los procesos que consumen más RAM.${NC}\n"
    ram_processes="No disponible"
fi

# Obtener los procesos que más CPU consumen
cpu_processes=$(ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6)
if [[ -z "$cpu_processes" ]]; then
    printf "${RED}Error al obtener los procesos que consumen más CPU.${NC}\n"
    cpu_processes="No disponible"
fi

# Imprimir la información de uso de CPU, RAM y procesos
printf "${YELLOW}>> Uso de CPU:${NC}\n"
printf "%s\n" "$cpu_usage"

printf "${YELLOW}>> Uso de RAM:${NC}\n"
printf "%s\n%s\n" "$ram_usage" "$swap_usage"

printf "${YELLOW}>> Procesos que más RAM están consumiendo:${NC}\n"
printf "%s\n" "$ram_processes"

printf "${YELLOW}>> Procesos que más CPU están consumiendo:${NC}\n"
printf "%s\n" "$cpu_processes"

# Fin del script
printf "${GREEN}===== Monitorización Completa =====${NC}\n"
printf "$(date '+%Y-%m-%d %H:%M:%S') - Monitorización completa\n"
# Fin del script
echo -e "${GREEN}===== Monitorización Completa =====${NC}" | tee -a $LOG_FILE
echo "$(date '+%Y-%m-%d %H:%M:%S') - Monitorización completa" >> $LOG_FILE
