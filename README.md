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
