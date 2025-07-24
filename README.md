# Install Scripts

curl -sSL https://raw.githubusercontent.com/phucbinhmt/install-scripts/main/install_n8n.sh > install_n8n.sh && chmod +x install_n8n.sh
sudo ./install_n8n.sh

# Update n8n

docker pull n8nio/n8n:latest
cd /home/n8n
docker-compose down
docker-compose up -d

sudo nano /home/n8n/docker-compose.yml
image: n8nio/n8n:latest