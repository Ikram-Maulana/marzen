#!/usr/bin/env bash
set -e

# The above shell script is defining variables for a base URL, Debian and Ubuntu components, supported
# Debian and Ubuntu versions, and retrieving the country code using the `curl` command with the
# ipinfo.io API. The script seems to be related to package repositories or software sources
# configuration for Debian and Ubuntu distributions.
BASE_URL="http://kartolo.sby.datautama.net.id"
DEBIAN_COMPONENTS="main contrib non-free"
UBUNTU_COMPONENTS="main restricted universe multiverse"
SUPPORTED_DEBIAN_VERSIONS=("bullseye" "bookworm")
SUPPORTED_UBUNTU_VERSIONS=("focal" "hirsute" "jammy" "noble")
COUNTRY_CODE=$(curl -s https://ipinfo.io/country)

# The above code defines a shell function `colorized_echo` that takes two arguments: a color and a
# text. The function then prints the text in the specified color using ANSI escape codes. The function
# supports colors such as red, green, yellow, blue, magenta, and cyan. If an unsupported color is
# provided, the text is printed as is.
colorized_echo() {
  local color=$1
  local text=$2

  case $color in
    "red") printf "\e[91m${text}\e[0m\n";;
    "green") printf "\e[92m${text}\e[0m\n";;
    "yellow") printf "\e[93m${text}\e[0m\n";;
    "blue") printf "\e[94m${text}\e[0m\n";;
    "magenta") printf "\e[95m${text}\e[0m\n";;
    "cyan") printf "\e[96m${text}\e[0m\n";;
    *) echo "${text}";;
  esac
}

# ================== Pre installation checks ==================

# The above code defines a shell function named `check_root` that checks if the script is being run as
# the root user (with superuser privileges). It does this by comparing the effective user ID (`EUID`)
# with 0, which is the user ID for the root user. If the EUID is not equal to 0, it prints a message
# in red color stating "This command must be run as root" and exits the script with an exit code of 1.
# This function is used to enforce that certain commands or operations within the script require root
# privileges to be executed.
check_root() {
  if [ "$EUID" -ne 0 ]; then
    colorized_echo "red" "This command must be run as root."
    exit 1
  fi
}

# The above shell script defines a function `detect_os` that determines the operating system and its
# version using the `lsb_release` command. It then checks if the detected OS and version are supported
# based on predefined arrays `SUPPORTED_DEBIAN_VERSIONS` and `SUPPORTED_UBUNTU_VERSIONS`. If the OS
# and version are not supported, it prints an error message in red color and exits the script with an
# exit code of 1. If the OS is neither Debian GNU/Linux nor Ubuntu, it also prints an error message
# and exits the script.
detect_os() {
  OS=$(lsb_release -si)
  OS_VERSION=$(lsb_release -sc)

  case $OS in
    "Debian GNU/Linux")
      if [[ ! " ${SUPPORTED_DEBIAN_VERSIONS[@]} " =~ " ${OS_VERSION} " ]]; then
        colorized_echo "red" "Unsupported Debian version. Exiting."
        exit 1
      fi
      ;;
    "Ubuntu")
      if [[ ! " ${SUPPORTED_UBUNTU_VERSIONS[@]} " =~ " ${OS_VERSION} " ]]; then
        colorized_echo "red" "Unsupported Ubuntu version. Exiting."
        exit 1
      fi
      ;;
    *)
      colorized_echo "red" "Unsupported operating system. Exiting."
      exit 1
      ;;
  esac
}

# The above shell script defines a function `update_local_mirror()` that updates the local mirror
# configuration for Debian or Ubuntu based on the provided operating system (``) and version
# (``).
update_local_mirror() {
  local os=$1
  local version=$2
  local components

  if [[ $os == "debian" ]]; then
    components=$DEBIAN_COMPONENTS
  elif [[ $os == "ubuntu" ]]; then
    components=$UBUNTU_COMPONENTS
  else
    echo "Unsupported OS: $os"
    return 1
  fi

  echo "#mirror_datautama_surabaya $version
  deb $base_url/$os $version $components
  deb $base_url/$os $version-updates $components" | sudo tee /etc/apt/sources.list > /dev/null

  if [[ $os == "debian" ]]; then
    echo "deb $BASE_URL/$os-security $version-security $components" | sudo tee -a /etc/apt/sources.list > /dev/null
  else
    echo "deb $BASE_URL/$os $version-backports $components
    deb $BASE_URL/$os $version-security $components" | sudo tee -a /etc/apt/sources.list > /dev/null
  fi
}

check_root
detect_os

# Check if the server is in Indonesia and prompt the user to use a local mirror for faster download.
if [[ $COUNTRY_CODE == "ID" ]]; then
  colorized_echo "green" "You are in Indonesia, using local mirror for faster download."
  read -p "Do you want to use local mirror? [Y/y/N/n]: " USE_LOCAL_MIRROR

  if [[ $USE_LOCAL_MIRROR =~ ^[Yy]$ ]]; then
    update_local_mirror $OS $OS_VERSION
  elif [[ $USE_LOCAL_MIRROR =~ ^[Nn]$ ]]; then
    colorized_echo "yellow" "Using default mirror from the operating system."
  else
    colorized_echo "red" "Invalid input. Using default mirror from the operating system."
  fi
else
  colorized_echo "yellow" "You are not in Indonesia, using default mirror from the operating system."
fi

# ================== Installation ==================


# The above shell script defines a function `validate_username` that prompts the user to enter a
# username. It then checks if the entered username meets certain criteria:
validate_username() {
  while true; do
    read -rp "Enter your panel username (only alphanumeric): " userpanel

    if [[ ! "$userpanel" =~ ^[A-Za-z0-9]+$ ]] || [[ "$userpanel" == *"admin"* ]]; then
      echo "Username must be only alphanumeric and do not contain the word 'admin'."
    else
      echo "$userpanel" > /etc/data/userpanel
      break
    fi
  done
}

# The above shell script defines a function `install_xray` that performs the following tasks:
# 1. Retrieves the latest version of Xray-core from the GitHub repository "XTLS/Xray-core".
# 2. Creates a directory `/var/lib/marzban/core` if it does not exist.
# 3. Downloads the Xray-linux-64.zip file for the retrieved version from the GitHub release.
# 4. Changes the current directory to `/var/lib/marzban/core`.
# 5. Unzips the downloaded xray-linux-64.zip file.
# 6. Removes the downloaded zip file after extraction.
install_xray() {
  mkdir -p /var/lib/marzban/core
  wget -O /var/lib/marzban/core/xray-linux-64.zip "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip"
  cd /var/lib/marzban/core && unzip xray-linux-64.zip && chmod +x xray && rm -f xray-linux-64.zip
  cd
}

# The above shell script is a function `install_vnstat` that installs the `vnstat` network traffic
# monitor tool on a Linux system. Here is a breakdown of the steps performed by the script:
install_vnstat() {
  apt update && apt -y install vnstat libsqlite3-dev
  /etc/init.d/vnstat restart
  # Hardcoded version for now, can be updated to latest version
  wget -O /tmp/vnstat.tar.gz "https://github.com/vergoh/vnstat/releases/download/v2.12/vnstat-2.12.tar.gz"
  tar -xzf /tmp/vnstat.tar.gz -C /tmp
  cd /tmp/vnstat-2.12
  ./configure --prefix=/usr --sysconfdir=/etc && make && make install
  cd
  if [ -d /var/lib/vnstat ]; then
    chown -R vnstat:vnstat /var/lib/vnstat
  fi
  systemctl enable vnstat
  /etc/init.d/vnstat restart
  rm -rf /tmp/vnstat.tar.gz /tmp/vnstat-2.12
}

# The above shell script defines a function `install_warp_proxy` that attempts to download a script
# file named `install_warp_proxy.sh` from either a primary URL or a fallback URL. Here's a breakdown
# of the script's functionality:
install_warp_proxy() {
    local primary_url="https://raw.githubusercontent.com/hamid-gh98/x-ui-scripts/main/install_warp_proxy.sh"
    local fallback_url="https://raw.githubusercontent.com/Ikram-Maulana/marzen/main/install_warp_proxy.sh"
    local destination="/root/warp"

    # Try to fetch from the primary URL
    if wget -O "$destination" "$primary_url"; then
        colorized_echo "green" "Fetched Warp Proxy script from primary URL."
    else
        colorized_echo "yellow" "Primary URL failed. Attempting to fetch from fallback URL..."
        # Try to fetch from the fallback URL
        if wget -O "$destination" "$fallback_url"; then
            colorized_echo "green" "Fetched Warp Proxy script from fallback URL."
        else
            colorized_echo "red" "Failed to fetch Warp Proxy script from both URLs."
            return 1
        fi
    fi

    sudo chmod +x "$destination"
    sudo bash "$destination" -y
}

# Ask user for domain
mkdir -p /etc/data
read -rp "Enter your domain: " domain
echo "$domain" > /etc/data/domain
domain=$(cat /etc/data/domain)

# Ask user for email, username and password
read -rp "Enter your email for Certbot: " email
validate_username
read -rp "Enter your panel password: " passpanel
echo "$passpanel" > /etc/data/passpanel

# Clear the screen and update the package repository
clear
cd
apt-get update

# Remove unused Module
colorized_echo "green" "Removing unused modules..."
apt-get -y --purge remove samba* apache2* sendmail* bind9*
colorized_echo "green" "Unused modules have been removed."

# Install BBR
colorized_echo "green" "Installing BBR..."
cat <<EOF >> /etc/sysctl.conf
fs.file-max = 500000
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 4096
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mem = 25600 51200 102400
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.core.rmem_max = 4000000
net.ipv4.tcp_mtu_probing = 1
net.ipv4.ip_forward = 1
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF
sysctl -p
colorized_echo "green" "BBR has been installed."

# Install the necessary packages
colorized_echo "green" "Installing the necessary packages..."
apt-get install -y libio-socket-inet6-perl libsocket6-perl libcrypt-ssleay-perl libnet-libidn-perl perl libio-socket-ssl-perl libwww-perl libpcre3 libpcre3-dev zlib1g-dev dbus iftop zip unzip wget net-tools curl nano sed screen gnupg gnupg1 bc apt-transport-https build-essential dirmngr dnsutils sudo at htop iptables bsdmainutils cron lsof lnav
colorized_echo "green" "The necessary packages have been installed."

# Set the timezone to Asia/Jakarta
colorized_echo "green" "Setting the timezone to Asia/Jakarta..."
timedatectl set-timezone Asia/Jakarta;
colorized_echo "green" "The timezone has been set to Asia/Jakarta."

# Install Marzban
colorized_echo "green" "Installing Marzban..."
sudo bash -c "$(curl -sL https://github.com/Ikram-Maulana/marzen-scripts/raw/master/marzen.sh)" @ install
colorized_echo "green" "Marzban has been installed."

# Install Subs
colorized_echo "green" "Installing Subscription..."
wget -N -P /var/lib/marzban/templates/subscription/ https://raw.githubusercontent.com/Ikram-Maulana/marzen/main/web/subscription/index.html
colorized_echo "green" "Subscription has been installed."

# Add Custom env
colorized_echo "green" "Adding custom env..."
wget -O /opt/marzban/.env "https://raw.githubusercontent.com/Ikram-Maulana/marzen/main/core/environment"
colorized_echo "green" "Custom env has been added."

# Install Xray
colorized_echo "green" "Installing Xray..."
install_xray
colorized_echo "green" "Xray has been installed."

# Profile
colorized_echo "green" "Installing Profile..."
echo -e 'profile' >> /root/.profile
wget -O /usr/bin/profile "https://raw.githubusercontent.com/Ikram-Maulana/marzen/main/core/greeting";
chmod +x /usr/bin/profile
apt install neofetch -y
# Ensure the .config/neofetch directory exists
mkdir -p /root/.config/neofetch
# Download the neofetch config file
wget -O /root/.config/neofetch/config.conf "https://raw.githubusercontent.com/Chick2D/neofetch-themes/main/small/dotfetch.conf"
wget -O /usr/bin/service-check "https://raw.githubusercontent.com/Ikram-Maulana/marzen/main/config/service-check.sh"
chmod +x /usr/bin/service-check
colorized_echo "green" "Profile has been installed."

# Install Docker Compose
colorized_echo "green" "Installing Docker Compose..."
wget -O /opt/marzban/docker-compose.yml "https://raw.githubusercontent.com/Ikram-Maulana/marzen/main/docker-compose.yml"
colorized_echo "green" "Docker Compose has been installed."

# Install vnstat
colorized_echo "green" "Installing vnstat..."
install_vnstat
colorized_echo "green" "vnstat has been installed successfully."

# Install Nginx
colorized_echo "green" "Installing Nginx..."
mkdir -p /var/log/nginx
touch /var/log/nginx/access.log
touch /var/log/nginx/error.log
wget -O /opt/marzban/nginx.conf "https://raw.githubusercontent.com/Ikram-Maulana/marzen/main/config/nginx.conf"
wget -O /opt/marzban/default.conf "https://raw.githubusercontent.com/Ikram-Maulana/marzen/main/config/vps.conf"
wget -O /opt/marzban/xray.conf "https://raw.githubusercontent.com/Ikram-Maulana/marzen/main/xray/xray.conf"
mkdir -p /var/www/html
wget -O /var/www/html/index.html "https://raw.githubusercontent.com/Ikram-Maulana/marzen/main/web/homepage/index.html"
colorized_echo "green" "Nginx has been installed."

# Install Socat
colorized_echo "green" "Installing Socat..."
apt install -y iptables curl socat xz-utils wget apt-transport-https gnupg gnupg2 gnupg1 dnsutils lsb-release socat cron bash-completion
colorized_echo "green" "Socat has been installed."

# Install Certbot
colorized_echo "green" "Installing Certbot..."
curl https://get.acme.sh | sh -s email=$email
/root/.acme.sh/acme.sh --server letsencrypt --register-account -m $email --issue -d $domain --standalone -k ec-256 --debug
/root/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /var/lib/marzban/xray.crt --keypath /var/lib/marzban/xray.key --ecc
wget -O /var/lib/marzban/xray_config.json "https://raw.githubusercontent.com/Ikram-Maulana/marzen/main/xray/xray-config.json"
colorized_echo "green" "Certbot has been installed."

# Install and configure firewall
if ! command -v ufw >/dev/null; then
    colorized_echo "green" "Installing UFW..."
    apt install ufw -y
fi
colorized_echo "green" "Configuring UFW rules..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw allow 7879/tcp
sudo ufw allow 8081/tcp
sudo ufw allow 1080/tcp
sudo ufw allow 1080/udp
colorized_echo "green" "Enabling UFW..."
yes | sudo ufw enable
colorized_echo "green" "UFW has been configured and enabled."

# Install Database
colorized_echo "green" "Installing Database..."
wget -O /var/lib/marzban/db.sqlite3 "https://github.com/Ikram-Maulana/marzen/raw/main/database/db.sqlite3"
colorized_echo "green" "Database has been installed."

# Install Warp Proxy
colorized_echo "green" "Installing Warp Proxy..."
install_warp_proxy
colorized_echo "green" "Warp Proxy has been installed."

# Finalize the installation
colorized_echo "green" "Finalizing the installation..."
apt autoremove -y
apt clean
cd /opt/marzban
sed -i "s/# SUDO_USERNAME = \"admin\"/SUDO_USERNAME = \"${userpanel}\"/" /opt/marzban/.env
sed -i "s/# SUDO_PASSWORD = \"admin\"/SUDO_PASSWORD = \"${passpanel}\"/" /opt/marzban/.env
docker compose down && docker compose up -d
marzban cli admin import-from-env -y
sed -i "s/SUDO_USERNAME = \"${userpanel}\"/# SUDO_USERNAME = \"admin\"/" /opt/marzban/.env
sed -i "s/SUDO_PASSWORD = \"${passpanel}\"/# SUDO_PASSWORD = \"admin\"/" /opt/marzban/.env
docker compose down && docker compose up -d
cd
profile
echo "For Marzban dashboard login data: " | tee -a log-install.txt
echo "-=================================-" | tee -a log-install.txt
echo "URL HTTPS : https://${domain}/dashboard" | tee -a log-install.txt
echo "URL HTTP  : http://${domain}:7879/dashboard" | tee -a log-install.txt
echo "username  : ${userpanel}" | tee -a log-install.txt
echo "password  : ${passpanel}" | tee -a log-install.txt
echo "-=================================-" | tee -a log-install.txt
colorized_echo "green" "The installation has been completed successfully."
rm /root/marzen.sh
colorized_echo "green" "Deleting default admin..."
marzban cli admin delete -u admin -y
colorized_echo "green" "Default admin has been deleted."
echo -e "Please reboot your server to apply all settings [default: Y/y](Y/y/N/n):"
read answer
if [[ $answer =~ ^[Nn]$ ]]; then
    colorized_echo "green" "Please reboot your server manually."
    exit 0
elif [[ $answer =~ ^[Yy]$ ]] || [[ -z $answer ]]; then
    cat /dev/null > ~/.bash_history && history -c && reboot
else
    colorized_echo "green" "Invalid input. Please reboot your server manually."
    exit 0
fi
