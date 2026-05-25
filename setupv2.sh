#!/bin/bash

set -e

echo "=== AWS LIVE STREAMING SETUP v2 (SAFE VERSION) ==="

# ----------------------------
# 1. SYSTEM UPDATE + DEPENDENCIES
# ----------------------------
sudo apt update -y
sudo apt install -y nginx libnginx-mod-rtmp ffmpeg \
python3 python3-pip python3-venv git curl

# ----------------------------
# 2. NGINX RTMP CONFIG
# ----------------------------
echo "=== Configuring NGINX RTMP ==="

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

sudo mkdir -p /var/www/html/hls
sudo chown -R www-data:www-data /var/www/html/hls

sudo nginx -t
sudo systemctl restart nginx

# ----------------------------
# 3. PLAYER HTML
# ----------------------------
echo "=== Creating Player ==="

sudo tee /var/www/html/player.html > /dev/null <<'EOF'
<!DOCTYPE html>
<html>
<head>
<title>Live Stream</title>
<script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
</head>
<body>
<video id="video" controls autoplay style="width:100%"></video>

<script>
const video = document.getElementById('video');
const src = '/hls/stream.m3u8';

if (Hls.isSupported()) {
    const hls = new Hls();
    hls.loadSource(src);
    hls.attachMedia(video);
} else {
    video.src = src;
}
</script>
</body>
</html>
EOF

# ----------------------------
# 4. PYTHON MONITORING APP
# ----------------------------
echo "=== Setting up Python Monitor ==="

cd /home/ubuntu

if [ ! -d "livestream-monitor" ]; then
    mkdir livestream-monitor
fi

cd livestream-monitor

python3 -m venv venv
source venv/bin/activate
pip install flask

cat > app.py << 'EOF'
from flask import Flask, jsonify, request
import os
import time

app = Flask(__name__)

HLS_PATH = "/var/www/html/hls/stream.m3u8"

viewer_sessions = {}
VIEWER_TIMEOUT = 30

def cleanup():
    now = time.time()
    expired = []

    for ip, last_seen in viewer_sessions.items():
        if now - last_seen > VIEWER_TIMEOUT:
            expired.append(ip)

    for ip in expired:
        del viewer_sessions[ip]

@app.route("/status")
def status():
    cleanup()
    return jsonify({
        "stream": "online" if os.path.exists(HLS_PATH) else "offline",
        "viewers": len(viewer_sessions)
    })

@app.route("/heartbeat")
def heartbeat():
    ip = request.remote_addr
    viewer_sessions[ip] = time.time()

    return jsonify({
        "message": "heartbeat received",
        "ip": ip
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
EOF

# ----------------------------
# 5. SYSTEMD SERVICE
# ----------------------------
echo "=== Setting up systemd ==="

sudo tee /etc/systemd/system/livestream-monitor.service > /dev/null <<EOF
[Unit]
Description=Livestream Monitor
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/livestream-monitor
ExecStart=/home/ubuntu/livestream-monitor/venv/bin/python3 /home/ubuntu/livestream-monitor/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable livestream-monitor
sudo systemctl restart livestream-monitor

# ----------------------------
# 6. VERIFICATION
# ----------------------------
echo "=== VERIFYING SYSTEM ==="

sleep 5

echo "--- STATUS ---"
curl -s http://localhost:5000/status || echo "STATUS FAILED"

echo "--- HEARTBEAT ---"
curl -s http://localhost:5000/heartbeat || echo "HEARTBEAT FAILED"

echo "--- SYSTEMD ---"
sudo systemctl status livestream-monitor --no-pager || true

# ----------------------------
# 7. DYNAMIC IP OUTPUT
# ----------------------------
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

echo "======================================"
echo "SETUP COMPLETE"
echo "ACCESS YOUR SYSTEM:"
echo "http://$PUBLIC_IP/player.html"
echo "http://$PUBLIC_IP:5000/status"
echo "http://$PUBLIC_IP:5000/heartbeat"
echo "======================================"
