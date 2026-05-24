#!/bin/bash

set -e

echo "=== AWS Live Streaming Setup Starting ==="

# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y nginx libnginx-mod-rtmp ffmpeg \
python3 python3-pip python3-venv git

echo "=== Configuring NGINX RTMP ==="

# Backup nginx config
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak

# Add RTMP block if not exists
if ! grep -q "rtmp {" /etc/nginx/nginx.conf; then
sudo bash -c 'cat >> /etc/nginx/nginx.conf' << 'EOF'

rtmp {
    server {
        listen 1935;

        application live {
            live on;
            record off;

            hls on;
            hls_path /var/www/html/hls;
            hls_fragment 3;
            hls_playlist_length 60;
        }
    }
}
EOF
fi

# Create HLS folder
sudo mkdir -p /var/www/html/hls
sudo chown -R www-data:www-data /var/www/html/hls

# Restart nginx
sudo nginx -t
sudo systemctl restart nginx

echo "=== Setting up Python Monitor ==="

cd ~

if [ ! -d "livestream-monitor" ]; then
    mkdir livestream-monitor
fi

cd livestream-monitor

python3 -m venv venv
source venv/bin/activate

pip install flask

cat > app.py << 'EOF'
from flask import Flask, jsonify
import os

app = Flask(__name__)

HLS_PATH = "/var/www/html/hls/stream.m3u8"

@app.route("/status")
def status():
    return jsonify({
        "stream": "online" if os.path.exists(HLS_PATH) else "offline"
    })

app.run(host="0.0.0.0", port=5000)
EOF

echo "=== Setup Complete ==="
echo "Next: configure systemd or run python manually"
