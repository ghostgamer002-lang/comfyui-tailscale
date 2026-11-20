#!/bin/bash
set -e

: "${TAILSCALE_AUTH_KEY:?Missing Tailscale key}"

mkdir -p /var/run/tailscale

tailscaled --tun=userspace-networking --state=mem: &

sleep 5

tailscale up \
  --auth-key="$TAILSCALE_AUTH_KEY" \
  --hostname=salad-comfyui \
  --accept-dns=false

tailscale serve --bg 7860

cd /opt/ComfyUI
exec python main.py --listen 127.0.0.1 --port 7860
