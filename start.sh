
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

tailscale serve --bg --http=80 7860

cd /opt/ComfyUI

if command -v rclone >/dev/null && \
   [ -n "${R2_ACCESS_KEY_ID:-}" ] && \
   [ -n "${R2_SECRET_ACCESS_KEY:-}" ] && \
   [ -n "${R2_ENDPOINT:-}" ] && \
   [ -n "${R2_BUCKET:-}" ]; then

  export RCLONE_CONFIG_R2_TYPE=s3
  export RCLONE_CONFIG_R2_PROVIDER=Cloudflare
  export RCLONE_CONFIG_R2_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
  export RCLONE_CONFIG_R2_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"
  export RCLONE_CONFIG_R2_ENDPOINT="$R2_ENDPOINT"
  export RCLONE_CONFIG_R2_NO_CHECK_BUCKET=true

  REMOTE="r2:${R2_BUCKET}"

  if rclone lsf "$REMOTE" >/dev/null; then
    RESTORE_OK=true

    for dir in models user input; do
      mkdir -p "$dir"
      if ! rclone copy "$REMOTE/$dir" "$PWD/$dir" \
          --transfers 3; then
        echo "R2 restore failed: $dir"
        RESTORE_OK=false
      fi
    done

    if [ "$RESTORE_OK" = true ]; then
      (
        while true; do
          for dir in models user input output; do
            rclone copy "/opt/ComfyUI/$dir" "$REMOTE/$dir" \
              --transfers 2 || echo "R2 backup failed: $dir"
          done
          sleep 300
        done
      ) &
    else
      echo "R2 backup disabled: restore incomplete"
    fi
  else
    echo "R2 unavailable: skipping restore and backup"
  fi
else
  echo "R2 configuration missing or rclone unavailable"
fi

exec python main.py --listen 127.0.0.1 --port 7860
