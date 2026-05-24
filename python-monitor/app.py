from flask import Flask, jsonify, request
import os
import time

app = Flask(__name__)

HLS_DIR = "/var/www/html/hls"
PLAYLIST = f"{HLS_DIR}/stream.m3u8"

viewer_sessions = {}

stream_start_time = time.time()

VIEWER_TIMEOUT = 30


def cleanup_viewers():
    current_time = time.time()

    expired = []

    for ip, last_seen in viewer_sessions.items():
        if current_time - last_seen > VIEWER_TIMEOUT:
            expired.append(ip)

    for ip in expired:
        del viewer_sessions[ip]


@app.route("/")
def home():
    return "AWS Live Streaming Monitoring API"


@app.route("/heartbeat")
def heartbeat():
    ip = request.remote_addr

    viewer_sessions[ip] = time.time()

    return jsonify({
        "message": "heartbeat received",
        "viewer_ip": ip
    })


@app.route("/status")
def status():

    cleanup_viewers()

    stream_online = os.path.exists(PLAYLIST)

    playlists = [f for f in os.listdir(HLS_DIR) if f.endswith(".m3u8")]

    uptime = int(time.time() - stream_start_time)

    return jsonify({
        "stream": "online" if stream_online else "offline",
        "active_streams": len(playlists),
        "viewers": len(viewer_sessions),
        "uptime_seconds": uptime,
        "last_updated": int(time.time())
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
