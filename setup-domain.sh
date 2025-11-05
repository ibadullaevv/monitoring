#!/bin/bash

echo "🌐 Monitoring tizimini domen bilan sozlash..."

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 1. Domenni so'rash
echo ""
echo -e "${YELLOW}📝 Sizning domeningiz nima?${NC}"
echo "Masalan: monitoring.uz yoki mon.example.com"
read -p "Domen: " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo -e "${RED}❌ Domen kiritilmadi!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Domen: $DOMAIN${NC}"

# 2. Variant tanlash
echo ""
echo -e "${YELLOW}🎨 Qaysi landing page ni xohlaysiz?${NC}"
echo "1) Homer Dashboard (Professional, tayyor dashboard)"
echo "2) Custom HTML (Chiroyli, minimal, tez)"
echo "3) Har ikkisi (Homer asosiy, Custom /custom da)"
read -p "Tanlov (1-3): " CHOICE

# 3. Kerakli papkalarni yaratish
echo ""
echo -e "${YELLOW}📁 Papkalar yaratilmoqda...${NC}"
mkdir -p nginx homer

# 4. Nginx config yaratish
echo -e "${YELLOW}📝 Nginx config yaratilmoqda...${NC}"

if [ "$CHOICE" == "1" ] || [ "$CHOICE" == "3" ]; then
    # Homer setup
    cat > nginx/nginx.conf << EOF
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server {
        listen 80;
        server_name $DOMAIN;

        # Homer Dashboard
        location / {
            proxy_pass http://homer:8080;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
        }

        # Grafana
        location /grafana/ {
            proxy_pass http://grafana:3000/;
            rewrite ^/grafana/(.*)$ /\$1 break;
            proxy_set_header Host \$host;
        }

        # Prometheus
        location /prometheus/ {
            proxy_pass http://prometheus:9090/;
            rewrite ^/prometheus/(.*)$ /\$1 break;
            proxy_set_header Host \$host;
        }

        # Alertmanager
        location /alertmanager/ {
            proxy_pass http://alertmanager:9093/;
            rewrite ^/alertmanager/(.*)$ /\$1 break;
            proxy_set_header Host \$host;
        }

        # cAdvisor
        location /cadvisor/ {
            proxy_pass http://cadvisor:8080/;
            rewrite ^/cadvisor/(.*)$ /\$1 break;
            proxy_set_header Host \$host;
        }

        # Node Exporter
        location /node-exporter/ {
            proxy_pass http://node-exporter:9100/;
            proxy_set_header Host \$host;
        }

        # Blackbox Exporter
        location /blackbox/ {
            proxy_pass http://blackbox-exporter:9115/;
            proxy_set_header Host \$host;
        }
    }
}
EOF

    # Homer config yaratish
    mkdir -p homer
    cat > homer/config.yml << 'EOFHOMER'
title: "Monitoring Dashboard"
subtitle: "Server va Saytlar Monitoring"

header: true
footer: '<p>Made with <i class="fas fa-heart"></i> for monitoring</p>'

theme: default
colors:
  light:
    highlight-primary: "#3367d6"
    highlight-secondary: "#4285f4"
    highlight-hover: "#5a95f5"
    background: "#f5f5f5"
    card-background: "#ffffff"
    text: "#363636"
    text-header: "#ffffff"
    text-title: "#303030"
    text-subtitle: "#424242"
    card-shadow: rgba(0, 0, 0, 0.1)
  dark:
    highlight-primary: "#3367d6"
    highlight-secondary: "#4285f4"
    highlight-hover: "#5a95f5"
    background: "#131313"
    card-background: "#2b2b2b"
    text: "#eaeaea"
    text-header: "#ffffff"
    text-title: "#fafafa"
    text-subtitle: "#f5f5f5"
    card-shadow: rgba(0, 0, 0, 0.4)

services:
  - name: "Monitoring Tizimi"
    icon: "fas fa-chart-line"
    items:
      - name: "Grafana"
        subtitle: "Dashboardlar va Vizualizatsiya"
        icon: "fas fa-chart-bar"
        tag: "analytics"
        url: "/grafana"
        target: "_blank"

      - name: "Prometheus"
        subtitle: "Metrikalar va Ma'lumotlar"
        icon: "fas fa-database"
        tag: "metrics"
        url: "/prometheus"
        target: "_blank"

      - name: "Alertmanager"
        subtitle: "Xabarlar va Ogohlantirishlar"
        icon: "fas fa-bell"
        tag: "alerts"
        url: "/alertmanager"
        target: "_blank"

      - name: "cAdvisor"
        subtitle: "Docker Container Monitoring"
        icon: "fab fa-docker"
        tag: "docker"
        url: "/cadvisor"
        target: "_blank"

  - name: "Server Ma'lumotlari"
    icon: "fas fa-server"
    items:
      - name: "Node Exporter"
        subtitle: "Server Metrikalar"
        icon: "fas fa-hdd"
        tag: "server"
        url: "/node-exporter/metrics"
        target: "_blank"

      - name: "Blackbox Exporter"
        subtitle: "Veb-sayt Monitoring"
        icon: "fas fa-globe"
        tag: "website"
        url: "/blackbox"
        target: "_blank"
EOFHOMER

    echo -e "${GREEN}✅ Homer Dashboard sozlandi${NC}"
fi

if [ "$CHOICE" == "2" ]; then
    # Custom HTML setup
    mkdir -p nginx/html

    # Custom HTML faylni yaratish (yuqoridagi HTML kodni bu yerga qo'ying)
    cat > nginx/html/index.html << 'EOFHTML'
<!DOCTYPE html>
<html lang="uz">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Monitoring Dashboard</title>
    <style>
        /* Bu yerga yuqoridagi CSS kodni qo'ying */
    </style>
</head>
<body>
    <!-- Bu yerga yuqoridagi HTML body kodni qo'ying -->
</body>
</html>
EOFHTML

    # Nginx config
    cat > nginx/nginx.conf << EOF
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server {
        listen 80;
        server_name $DOMAIN;

        # Custom Landing Page
        location = / {
            root /usr/share/nginx/html;
            index index.html;
        }

        # Static files
        location /assets/ {
            root /usr/share/nginx/html;
        }

        # Servislar
        location /grafana/ {
            proxy_pass http://grafana:3000/;
            rewrite ^/grafana/(.*)$ /\$1 break;
        }

        location /prometheus/ {
            proxy_pass http://prometheus:9090/;
            rewrite ^/prometheus/(.*)$ /\$1 break;
        }

        location /alertmanager/ {
            proxy_pass http://alertmanager:9093/;
            rewrite ^/alertmanager/(.*)$ /\$1 break;
        }

        location /cadvisor/ {
            proxy_pass http://cadvisor:8080/;
            rewrite ^/cadvisor/(.*)$ /\$1 break;
        }

        location /node-exporter/ {
            proxy_pass http://node-exporter:9100/;
        }

        location /blackbox/ {
            proxy_pass http://blackbox-exporter:9115/;
        }
    }
}
EOF

    echo -e "${GREEN}✅ Custom HTML landing page sozlandi${NC}"
fi

# 5. Docker Compose yangilash
echo ""
echo -e "${YELLOW}🐳 Docker Compose yangilanmoqda...${NC}"

# Nginx servisni qo'shish
if ! grep -q "nginx:" docker-compose.yml; then
    cat >> docker-compose.yml << 'EOF'

  # Nginx Reverse Proxy
  nginx:
    image: nginx:alpine
    container_name: nginx-proxy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/html:/usr/share/nginx/html:ro
    networks:
      - monitoring
EOF
fi

if [ "$CHOICE" == "1" ] || [ "$CHOICE" == "3" ]; then
    # Homer servisni qo'shish
    if ! grep -q "homer:" docker-compose.yml; then
        cat >> docker-compose.yml << 'EOF'

  # Homer Dashboard
  homer:
    image: b4bz/homer:latest
    container_name: homer
    restart: unless-stopped
    volumes:
      - ./homer:/www/assets
    environment:
      - INIT_ASSETS=1
    networks:
      - monitoring
EOF
    fi
fi

# 6. DNS sozlash yo'riqnomasi
echo ""
echo -e "${GREEN}✅ Konfiguratsiya tayyor!${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${YELLOW}📋 DNS SOZLASH${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Domen provayderingizda quyidagi A recordni qo'shing:"
echo ""
echo "  Type: A"
echo "  Name: $DOMAIN (yoki @)"
echo "  Value: $(curl -s ifconfig.me)"
echo "  TTL: 3600"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 7. Ishga tushirish
read -p "Docker containerlarni ishga tushiramizmi? (y/n): " START

if [ "$START" == "y" ]; then
    echo ""
    echo -e "${YELLOW}🚀 Ishga tushirilmoqda...${NC}"
    docker compose down
    docker compose up -d

    sleep 5

    echo ""
    docker compose ps

    echo ""
    echo -e "${GREEN}✅ Tayyor!${NC}"
    echo ""
    echo "🌐 Saytingiz: http://$DOMAIN"
    echo ""
    echo "Servislar:"
    echo "  • Grafana:       http://$DOMAIN/grafana"
    echo "  • Prometheus:    http://$DOMAIN/prometheus"
    echo "  • Alertmanager:  http://$DOMAIN/alertmanager"
    echo "  • cAdvisor:      http://$DOMAIN/cadvisor"
    echo ""
fi

echo -e "${YELLOW}💡 Maslahat: SSL (HTTPS) uchun Certbot o'rnating!${NC}"
echo "   sudo apt install certbot python3-certbot-nginx"
echo "   sudo certbot --nginx -d $DOMAIN"
echo ""