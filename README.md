# AWS Live Streaming System

## Overview
This project demonstrates a live streaming pipeline using AWS EC2, NGINX-RTMP, HLS, and Python monitoring.

## Architecture
OBS → RTMP → NGINX → HLS → Browser Player

## Features
- Live streaming via OBS
- RTMP ingestion
- HLS playback in browser
- Python Flask monitoring API
- systemd service deployment

## API Endpoints
- /status → stream metrics
- /heartbeat → viewer tracking

## Tech Stack
- AWS EC2 (Ubuntu 24.04)
- NGINX + RTMP module
- Python Flask
- HLS.js
- systemd

## To Start the service on a fresh EC2, 
- on a newly created EC2, use ports ssh 22, http 80, https 443, RTMP 1935, PythonFlaskAPI 5000 
- if one windows machine -> open powershell -> ssh -i "path to .pem key" ubuntu@EC2IP
- ls -lh
- move to directory aws-live-streaming with: cd aws-live-streaming
- ls -lh
- run the setupv2.sh file
-   by first changing the persmissions via, chmod +x setupv2.sh
-   then run, ./setupv2.sh
-   it will take 3-5 min to load everything, for further tests
-   use http://xx.xx.xxx.xxx/player.html
-   VLC -> open network stream -> http://xx.xx.xxx.xxx/hls/stream.m3u8
-   To check on the player and latency etc, use hls.js.video-dev.org/demo, put in the url field: http://xx.xx.xxx.xxx/hls/stream.m3u8, and click play
-   To check Python Flask API, status: http://xx.xx.xxx.xxx:5000/status, heartbeat: http://xx.xx.xxx.xxx:5000/heartbeat
