# Marzen (Marzban Extended)

Marzen is a proxy management tool that provides a simple and easy-to-use user interface for managing hundreds of proxy accounts. This tool is modified version of [Marzban](https://github.com/Gozargah/Marzban?utm_source=marzen&utm_medium=redirect&utm_campaign=marzen) and forked version of [MarLing](https://github.com/GawrAme/MarLing?utm_source=marzen&utm_medium=redirect&utm_campaign=marzen) adding Nginx for WebSocket, Http Upgrade, and gRPC single port support.

## Supported Protocols

- Trojan
- Vmess
- Vless
- Shadowsocks

## Requirements

- A VPS running Ubuntu 20.04 (or newer) or Debian 11 (or newer), equipped with at least 1GB of RAM and 1 CPU core.
- A domain that is already configured to point to your VPS's IP address via Cloudflare.

## Installation

- Update and upgrade your system

  ```bash
  apt-get update && apt-get upgrade -y && update-grub && reboot
  ```

- Make sure you logged in as root

  ```bash
  wget https://raw.githubusercontent.com/Ikram-Maulana/marzen/main/marzen.sh && chmod +x marzen.sh && ./marzen.sh
  ```

Once the installation is complete:

- You will see the logs that you can stop watching them by closing the terminal or pressing Ctrl+C
- The Marzban files will be located at /opt/marzban
  The configuration file can be found at /opt/marzban/.env (refer to configurations section to see variables)
- The data files will be placed at /var/lib/marzban
- You can access the Marzban dashboard by opening a web browser and navigating to http://YOUR_DOMAIN:8000/dashboard/ (replace YOUR_DOMAIN with the actual domain)
- You can change the configuration by editing the .env file

  ```bash
  nano /opt/marzban/.env
  ```

- You can restart the Marzban service by running

  ```bash
  marzban restart
  ```

- You can see logs by running

  ```bash
  marzban logs
  ```

- You can update Marzban by running

  ```bash
  marzban update
  ```

## Cloudflare Configuration

- Go to your Cloudflare dashboard and click on the domain you want to use with Marzban.
- Click on the DNS tab and add an A record with the name "marzban" and the value of your server's IP address.
- Click on the SSL/TLS tab and set the SSL/TLS encryption mode to Full (strict).
- Click on Network tab and set the gRPC and WebSocket to "On".

## Marzban Host Configuration

- Go to the Marzban dashboard and click on the "Hosts" tab.
- Replace every instance of "{SERVER_IP}" with your domain, which should already be set up in Cloudflare.

## Resources

- [Gozargah](https://github.com/Gozargah/Marzban)
- [GawrAme](https://github.com/GawrAme/MarLing)
- [hamid-gh98](https://github.com/hamid-gh98)
- [x0sina](https://github.com/x0sina/marzban-sub)
