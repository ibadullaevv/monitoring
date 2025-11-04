#!/bin/bash

echo "🚀 Prometheus + Grafana Monitoring tizimini o'rnatish boshlandi..."

# Ranglar
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Kerakli papkalarni yaratish
echo -e "${YELLOW}📁 Papkalar yaratilmoqda...${NC}"
mkdir -p prometheus
mkdir -p blackbox
mkdir -p alertmanager
mkdir -p grafana/provisioning/datasources
mkdir -p grafana/provisioning/dashboards

# Docker va Docker Compose borligini tekshirish
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker o'rnatilmagan!${NC}"
    echo "Docker o'rnatish: https://docs.docker.com/engine/install/"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose o'rnatilmagan!${NC}"
    echo "Docker Compose o'rnatish: https://docs.docker.com/compose/install/"
    exit 1
fi

echo -e "${GREEN}✅ Docker va Docker Compose topildi${NC}"

# Konfiguratsiya fayllarini tekshirish
files=(
    "docker-compose.yml"
    "prometheus/prometheus.yml"
    "prometheus/alerts.yml"
    "blackbox/blackbox.yml"
    "alertmanager/alertmanager.yml"
    "grafana/provisioning/datasources/datasource.yml"
    "grafana/provisioning/dashboards/dashboard.yml"
)

missing_files=0
for file in "${files[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}❌ $file topilmadi${NC}"
        missing_files=$((missing_files + 1))
    fi
done

if [ $missing_files -gt 0 ]; then
    echo -e "${RED}⚠️  $missing_files ta fayl topilmadi. Iltimos barcha fayllarni yarating.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Barcha konfiguratsiya fayllari topildi${NC}"

# Saytlar ro'yxatini so'rash
echo ""
echo -e "${YELLOW}🌐 Monitoring qilmoqchi bo'lgan saytlaringizni kiriting (har birini yangi qatorga):${NC}"
echo "Masalan: https://example.uz"
echo "Tugatish uchun bo'sh qator kiriting"
echo ""

sites=()
while true; do
    read -p "Sayt URL: " site
    if [ -z "$site" ]; then
        break
    fi
    sites+=("$site")
done

# Agar saytlar kiritilgan bo'lsa, prometheus.yml ga qo'shish
if [ ${#sites[@]} -gt 0 ]; then
    echo -e "${YELLOW}📝 Saytlar prometheus.yml ga qo'shilmoqda...${NC}"

    # Saytlarni YAML formatiga o'tkazish
    site_config=""
    for site in "${sites[@]}"; do
        site_config="${site_config}          - $site\n"
    done

    # prometheus.yml dagi example saytlarni o'zgartirish
    sed -i.bak "/- https:\/\/example.uz/d" prometheus/prometheus.yml
    sed -i "/targets:/a\\          ${sites[0]}" prometheus/prometheus.yml

    for ((i=1; i<${#sites[@]}; i++)); do
        sed -i "/targets:/a\\          ${sites[$i]}" prometheus/prometheus.yml
    done

    echo -e "${GREEN}✅ ${#sites[@]} ta sayt qo'shildi${NC}"
fi

# Telegram bot sozlash
echo ""
read -p "Telegram bot orqali xabar olmoqchimisiz? (y/n): " telegram_choice
if [ "$telegram_choice" = "y" ]; then
    echo ""
    echo "Telegram bot yaratish:"
    echo "1. Telegram'da @BotFather'ga yozing"
    echo "2. /newbot buyrug'ini yuboring"
    echo "3. Bot nomini kiriting"
    echo "4. Bot token'ini oling"
    echo ""
    read -p "Bot token: " bot_token
    read -p "Chat ID (o'zingizning Telegram ID): " chat_id

    # alertmanager.yml ga token va chat_id ni qo'shish
    sed -i "s/SIZNING_BOT_TOKEN/$bot_token/g" alertmanager/alertmanager.yml
    sed -i "s/123456789/$chat_id/g" alertmanager/alertmanager.yml

    echo -e "${GREEN}✅ Telegram bot sozlandi${NC}"
fi

# Docker Compose ishga tushirish
echo ""
echo -e "${YELLOW}🐳 Docker containerlar ishga tushirilmoqda...${NC}"
docker-compose up -d

# Container holatini tekshirish
sleep 5
echo ""
echo -e "${YELLOW}📊 Containerlar holati:${NC}"
docker-compose ps

echo ""
echo -e "${GREEN}✅ O'rnatish tugadi!${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🎉 Monitoring tizimi ishga tushdi!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📍 Servislarga kirish:"
echo "   Grafana:       http://localhost:3000"
echo "   Prometheus:    http://localhost:9090"
echo "   Alertmanager:  http://localhost:9093"
echo "   cAdvisor:      http://localhost:8080"
echo ""
echo "🔐 Grafana login:"
echo "   Username: admin"
echo "   Password: admin123"
echo ""
echo "📚 Qo'shimcha buyruqlar:"
echo "   Loglarni ko'rish:     docker-compose logs -f"
echo "   To'xtatish:           docker-compose stop"
echo "   O'chirish:            docker-compose down"
echo "   Qayta ishga tushirish: docker-compose restart"
echo ""
echo "🎯 Keyingi qadamlar:"
echo "   1. Grafana'ga kiring: http://localhost:3000"
echo "   2. Dashboard import qiling: ID 1860 (Node Exporter)"
echo "   3. Dashboard import qiling: ID 7587 (Blackbox Exporter)"
echo "   4. Dashboard import qiling: ID 193 (Docker)"
echo ""
echo -e "${YELLOW}💡 Maslahat: prometheus/prometheus.yml faylida saytlaringizni qo'shishni unutmang!${NC}"
echo ""