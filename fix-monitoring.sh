#!/bin/bash

echo "🔧 Monitoring tizimini tuzatish..."

# Ranglar
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Barcha containerlarni to'xtatish
echo -e "${YELLOW}⏹️  Barcha containerlarni to'xtatish...${NC}"
docker compose down
sleep 3

# 2. Eski imagelarni tozalash
echo -e "${YELLOW}🧹 Eski imagelarni tozalash...${NC}"
docker system prune -f

# 3. Fayllarning huquqlarini tekshirish
echo -e "${YELLOW}🔐 Fayllar huquqlarini sozlash...${NC}"
chmod -R 755 prometheus/ blackbox/ alertmanager/ grafana/

# 4. Konfiguratsiya fayllarini tekshirish
echo -e "${YELLOW}📋 Konfiguratsiya fayllarini tekshirish...${NC}"

check_file() {
    if [ ! -f "$1" ]; then
        echo -e "${RED}❌ $1 topilmadi${NC}"
        return 1
    else
        echo -e "${GREEN}✅ $1 topildi${NC}"
        return 0
    fi
}

check_file "docker-compose.yml"
check_file "prometheus/prometheus.yml"
check_file "prometheus/alerts.yml"
check_file "blackbox/blackbox.yml"
check_file "alertmanager/alertmanager.yml"

# 5. YAML fayllarni validatsiya qilish
echo -e "${YELLOW}🔍 YAML sintaksisini tekshirish...${NC}"

# Prometheus config test
docker run --rm -v "$(pwd)/prometheus:/prometheus" prom/prometheus:latest \
    promtool check config /prometheus/prometheus.yml 2>&1 | head -20

# 6. Portlarni tekshirish
echo -e "${YELLOW}🔌 Portlarni tekshirish...${NC}"

check_port() {
    if ss -tulpn | grep -q ":$1 "; then
        echo -e "${RED}⚠️  Port $1 band${NC}"
        echo "   Band qilgan process:"
        ss -tulpn | grep ":$1 "
        return 1
    else
        echo -e "${GREEN}✅ Port $1 bo'sh${NC}"
        return 0
    fi
}

check_port 9090
check_port 3000
check_port 9100
check_port 9115
check_port 8080
check_port 9093

# 7. Har bir servисни alohida ishga tushirish
echo ""
echo -e "${YELLOW}🚀 Servislarni bosqichma-bosqich ishga tushirish...${NC}"
echo ""

# Node Exporter
echo -e "${YELLOW}1️⃣  Node Exporter ishga tushirilmoqda...${NC}"
docker compose up -d node-exporter
sleep 5
if docker compose ps node-exporter | grep -q "Up"; then
    echo -e "${GREEN}✅ Node Exporter ishga tushdi${NC}"
else
    echo -e "${RED}❌ Node Exporter ishlamadi. Loglar:${NC}"
    docker compose logs node-exporter
    exit 1
fi

# Blackbox Exporter
echo -e "${YELLOW}2️⃣  Blackbox Exporter ishga tushirilmoqda...${NC}"
docker compose up -d blackbox-exporter
sleep 5
if docker compose ps blackbox-exporter | grep -q "Up"; then
    echo -e "${GREEN}✅ Blackbox Exporter ishga tushdi${NC}"
else
    echo -e "${RED}❌ Blackbox Exporter ishlamadi. Loglar:${NC}"
    docker compose logs blackbox-exporter
    exit 1
fi

# Prometheus
echo -e "${YELLOW}3️⃣  Prometheus ishga tushirilmoqda...${NC}"
docker compose up -d prometheus
sleep 10
if docker compose ps prometheus | grep -q "Up"; then
    echo -e "${GREEN}✅ Prometheus ishga tushdi${NC}"
    echo "   Test: curl -s http://localhost:9090/-/healthy"
    curl -s http://localhost:9090/-/healthy
else
    echo -e "${RED}❌ Prometheus ishlamadi. Loglar:${NC}"
    docker compose logs prometheus
    exit 1
fi

# Alertmanager
echo -e "${YELLOW}4️⃣  Alertmanager ishga tushirilmoqda...${NC}"
docker compose up -d alertmanager
sleep 5
if docker compose ps alertmanager | grep -q "Up"; then
    echo -e "${GREEN}✅ Alertmanager ishga tushdi${NC}"
else
    echo -e "${RED}❌ Alertmanager ishlamadi. Loglar:${NC}"
    docker compose logs alertmanager
    exit 1
fi

# cAdvisor
echo -e "${YELLOW}5️⃣  cAdvisor ishga tushirilmoqda...${NC}"
docker compose up -d cadvisor
sleep 5
if docker compose ps cadvisor | grep -q "Up"; then
    echo -e "${GREEN}✅ cAdvisor ishga tushdi${NC}"
else
    echo -e "${RED}❌ cAdvisor ishlamadi. Loglar:${NC}"
    docker compose logs cadvisor
fi

# Grafana
echo -e "${YELLOW}6️⃣  Grafana ishga tushirilmoqda...${NC}"
docker compose up -d grafana
sleep 10
if docker compose ps grafana | grep -q "Up"; then
    echo -e "${GREEN}✅ Grafana ishga tushdi${NC}"
else
    echo -e "${RED}❌ Grafana ishlamadi. Loglar:${NC}"
    docker compose logs grafana
    exit 1
fi

# 8. Yakuniy tekshiruv
echo ""
echo -e "${YELLOW}📊 Barcha servislar holati:${NC}"
docker compose ps

echo ""
echo -e "${YELLOW}🔍 Servislarni tekshirish:${NC}"

# Prometheus
if curl -s http://localhost:9090/-/healthy | grep -q "Healthy"; then
    echo -e "${GREEN}✅ Prometheus: http://localhost:9090${NC}"
else
    echo -e "${RED}❌ Prometheus ishlamayapti${NC}"
fi

# Grafana
if curl -s http://localhost:3000/api/health | grep -q "ok"; then
    echo -e "${GREEN}✅ Grafana: http://localhost:3000${NC}"
else
    echo -e "${RED}❌ Grafana ishlamayapti${NC}"
fi

# Alertmanager
if curl -s http://localhost:9093/-/healthy | grep -q "Healthy"; then
    echo -e "${GREEN}✅ Alertmanager: http://localhost:9093${NC}"
else
    echo -e "${RED}❌ Alertmanager ishlamayapti${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Monitoring tizimi tayyor!${NC}"
echo ""
echo "📍 Kirish manzillari:"
echo "   Grafana:       http://localhost:3000 (admin/admin123)"
echo "   Prometheus:    http://localhost:9090"
echo "   Alertmanager:  http://localhost:9093"
echo ""
echo "📚 Foydali buyruqlar:"
echo "   docker compose logs -f              # Barcha loglar"
echo "   docker compose logs -f prometheus   # Prometheus loglari"
echo "   docker compose restart prometheus   # Qayta ishga tushirish"
echo "   docker compose down                 # To'xtatish"
echo ""