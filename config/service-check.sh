#!/usr/bin/env bash
set -e

panel_port=$(netstat -tunlp | grep 'python' | awk '{split($4, a, ":"); print a[2]}')

# Color constants
RED='\033[0;31m';
GREEN='\033[0;32m';
YELLOW='\033[0;33m';
BLUE='\033[0;34m';
PURPLE='\033[0;35m';
CYAN='\033[0;36m';
LIGHT='\033[0;37m';
NC='\033[0m';

# Status constants
ERROR="[${RED} ERROR ${NC}]";
INFO="[${YELLOW} INFO ${NC}]";
OKEY="[${GREEN} OKEY ${NC}]";
PENDING="[${YELLOW} PENDING ${NC}]";
SEND="[${YELLOW} SEND ${NC}]";
RECEIVE="[${YELLOW} RECEIVE ${NC}]";

# The `service_status_check()` function is a shell script function that checks the status of a service
# running on a specific port. Here's a breakdown of what the function does:
service_status_check() {
  local service_name=$1
  local port=$2
  local process_name=$3

  if [[ $(netstat -ntlp | grep -i "$process_name" | grep -i "0.0.0.0:$port" | awk '{print $4}' | cut -d: -f2 | xargs | sed -e 's/ /, /g') == "$port" ]]; then
    echo "${GREEN}Okay${NC}"
  else
    echo "${RED}Not Okay${NC}"
  fi
}

# The `check_ufw_status()` function is checking the status of the Uncomplicated Firewall (UFW)
# service. Here's a breakdown of what the function does:
check_ufw_status() {
  if [[ $(systemctl status ufw | grep -w Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == 'active' ]]; then
    echo "${GREEN}Okay${NC}"
  else
    echo "${RED}Not Okay${NC}"
  fi
}

# Service status check
NGINX=$(service_status_check "Nginx" "443" "nginx")
MARZ=$(service_status_check "Marzban Panel" "$panel_port" "python")
UFW=$(check_ufw_status)

# Display the service status
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m${NC}"
echo -e "\E[44;1;39m            ⇱ Service Information ⇲             \E[0m"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m${NC}"
echo -e "❇️ Nginx                :$NGINX"
echo -e "❇️ Firewall             :$UFW"
echo -e "❇️ Marzban Panel        :$MARZ"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m${NC}"
echo ""
