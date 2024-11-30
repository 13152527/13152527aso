#!/bin/bash
# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
echo -e "${GREEN}===== Monitorizacion Script =====${NC}"
# 1. uso de cpu
echo -e "${YELLOW}\n>> Uso de CPU: ${NC}"
mpstat | awk '/all/ {print "CPU Load: " $3 "% idle"}'
# 2. uso de RAM
echo -e "${YELLOW}\n>> Uso de RAM: ${NC}"
free -h | awk '/Mem/ {print "Total Memory: " $2 "\nUsed: " $3 "\nFree: " $4}'
echo -e "Swap:\n"$(free -h | awk '/Swap/ {print "Total: " $2 ", Used: " $3 ", Free: " $4}')
# 3. Uso de disco
echo -e "${YELLOW}\n>> Uso de disco: ${NC}"
df -h | grep '^/dev' | awk '{print $1 ": " $5 " used, " $4 " available"}'
# 5. Procesos que mas RAM consumen
echo -e "${YELLOW}\n>> procesos que mas RAM estan consumiendo: ${NC}"
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6
# 6. Procesos que mas CPU consumen
echo -e "${YELLOW}\n>> Procesos que mas CPU estan consumiendo: ${NC}"
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6
# 7. Monitorizacion de los logs
echo -e "${YELLOW}\n>> Errores en System Logs: ${NC}"
journalctl -p 3 -xb | tail -n 10
echo -e "${GREEN}===== Monitorizacion Completa =====${NC}"
