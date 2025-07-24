#!/bin/bash

# Kiểm tra quyền root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Vui lòng chạy script với quyền root (sudo)"
   exit 1
fi

# Lấy domain từ người dùng
read -p "🌐 Nhập domain/subdomain của bạn (ví dụ: n8n.example.com): " DOMAIN

# Kiểm tra domain đã trỏ đúng IP chưa
check_domain() {
    local domain=$1
    local server_ip=$(curl -s https://api.ipify.org)
    local domain_ip=$(dig +short "$domain" | tail -n1)

    if [[ "$domain_ip" == "$server_ip" ]]; then
        return 0
    else
        return 1
    fi
}

if ! check_domain "$DOMAIN"; then
    echo "❌ Domain $DOMAIN chưa trỏ đúng về IP máy chủ."
    echo "➡️  Vui lòng cập nhật DNS trỏ $DOMAIN về IP: $(curl -s https://api.ipify.org)"
    exit 1
fi

echo "✅ Domain $DOMAIN đã trỏ đúng về server. Tiếp tục cài đặt..."

# Biến và thư mục
N8N_DIR="/home/n8n"
mkdir -p "$N8N_DIR"

# Cài Docker & Docker Compose (compose plugin)
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release

# Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Tạo docker-compose.yml (sử dụng image mới nhất)
cat << EOF > "$N8N_DIR/docker-compose.yml"
version: "3.8"
services:
  n8n:
    image: n8nio/n8n:latest
    restart: always
    environment:
      - N8N_HOST=$DOMAIN
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - NODE_ENV=production
      - WEBHOOK_URL=https://$DOMAIN
      - GENERIC_TIMEZONE=Asia/Ho_Chi_Minh
      - N8N_DIAGNOSTICS_ENABLED=false
    volumes:
      - n8n_data:/home/node/.n8n
    networks:
      - n8n_network
    dns:
      - 8.8.8.8
      - 1.1.1.1

  caddy:
    image: caddy:2
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    depends_on:
      - n8n
    networks:
      - n8n_network

volumes:
  n8n_data:
  caddy_data:
  caddy_config:

networks:
  n8n_network:
    driver: bridge
EOF

# Tạo file Caddyfile
cat << EOF > "$N8N_DIR/Caddyfile"
$DOMAIN {
    reverse_proxy n8n:5678
}
EOF

# Gán quyền đúng
chown -R 1000:1000 "$N8N_DIR"
chmod -R 755 "$N8N_DIR"

# Khởi động container
cd "$N8N_DIR"
docker compose pull
docker compose up -d

# ✅ Thông báo hoàn tất
echo ""
echo "╔════════════════════════════════════════════════════╗"
echo "║ ✅ n8n đã được cài đặt thành công!                ║"
echo "║ 🌍 Truy cập: https://$DOMAIN                      ║"
echo "║ 📁 Thư mục: $N8N_DIR                              ║"
echo "║ 🧠 Hướng dẫn học: https://n8n-basic.mecode.pro   ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""
