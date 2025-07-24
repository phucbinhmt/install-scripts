#!/bin/bash

# Tên container và port riêng
CONTAINER_NAME="n8n_new"
PORT=5679
DATA_DIR="/home/n8n-new"

# Nhập domain mới nếu bạn có reverse proxy
read -p "🌐 Nhập domain cho n8n mới (bấm Enter nếu không có): " DOMAIN

# Tạo thư mục chứa dữ liệu riêng biệt
mkdir -p "$DATA_DIR"

# Tạo docker-compose.yml tạm cho phiên bản mới
cat << EOF > "$DATA_DIR/docker-compose.yml"
version: "3.8"
services:
  $CONTAINER_NAME:
    image: n8nio/n8n:latest
    container_name: $CONTAINER_NAME
    restart: always
    environment:
      - N8N_PORT=$PORT
      - N8N_PROTOCOL=http
      - GENERIC_TIMEZONE=Asia/Ho_Chi_Minh
      - N8N_DIAGNOSTICS_ENABLED=false
      $( [[ -n "$DOMAIN" ]] && echo "- N8N_HOST=$DOMAIN" )
      $( [[ -n "$DOMAIN" ]] && echo "- WEBHOOK_URL=http://$DOMAIN" )
    ports:
      - "$PORT:$PORT"
    volumes:
      - n8n_new_data:/home/node/.n8n
    dns:
      - 8.8.8.8
      - 1.1.1.1

volumes:
  n8n_new_data:
EOF

# Phân quyền và khởi chạy
chown -R 1000:1000 "$DATA_DIR"
cd "$DATA_DIR"
docker compose up -d

echo ""
echo "✅ Đã khởi chạy container $CONTAINER_NAME với n8n mới nhất"
echo "➡️  Truy cập qua: http://<your-server-ip>:$PORT"
[[ -n "$DOMAIN" ]] && echo "🌐 Hoặc: http://$DOMAIN (nếu bạn đã trỏ domain về IP)"
