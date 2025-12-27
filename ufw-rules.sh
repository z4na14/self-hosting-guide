#!/bin/bash

echo "Resetting UFW"
sudo ufw --force reset

sudo ufw default deny incoming
sudo ufw default allow outgoing

echo "Allowing SSH and Web traffic"
sudo ufw allow 22/tcp  # SSH
sudo ufw allow 80/tcp  # HTTP (NPM / Certbot)
sudo ufw allow 443/tcp # HTTPS (Web traffic)
sudo ufw allow 81/tcp  # Nginx Proxy Manager UI

echo "Configuring Pi-hole Ports (DNS & DHCP)"
sudo ufw allow 53/tcp  # DNS
sudo ufw allow 53/udp  # DNS
sudo ufw allow 67/udp  # DHCP IPv4 (Server)
sudo ufw allow 68/udp  # DHCP IPv4 (Client)
sudo ufw allow 546/udp # DHCP IPv6 (Client)
sudo ufw allow 547/udp # DHCP IPv6 (Server)

echo "Allowing WireGuard"
sudo ufw allow 51820/udp # WireGuard VPN Tunnel
sudo ufw allow 51821/tcp # WG-Easy Web UI

echo "Forgejo ports"
sudo ufw allow 222/tcp
sudo ufw allow 222/udp

echo "Services range of ports for dockers"
sudo ufw allow 1000:9999/tcp
sudo ufw allow 1000:9999/udp

echo "Finalizing"
sudo ufw --force enable
sudo ufw status numbered
