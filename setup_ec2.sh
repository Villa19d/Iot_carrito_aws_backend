#!/usr/bin/env bash
# ============================================================================
# setup_ec2.sh - Carrito IoT backend: one-shot deploy on Amazon Linux 2023
# ----------------------------------------------------------------------------
# What it does:
#   1) dnf update + install git, python3.11, python3.11-pip
#      (AL2023 ships python3 = 3.9, but the pinned deps need >= 3.10)
#   2) clone the backend repo on branch feat/portfolio-demo into
#      /home/ec2-user/Carrito_backend
#   3) cd into Carrito_backend/TestingAPIWebsockets/WebSockets
#   4) create + activate a venv
#   5) install requirements.txt (auto-converting it from UTF-16 to UTF-8 if
#      needed, because pip only reads UTF-8 requirement files)
#   6) write /etc/systemd/system/carrito-api.service (correct WorkingDirectory
#      + EnvironmentFile=.env)
#   7) enable + start carrito-api.service
#
# Usage (on the EC2 instance):
#   chmod +x setup_ec2.sh && ./setup_ec2.sh
#   ...or paste the whole file content into the terminal.
#
# NOTE: after it finishes, open TCP ports 5000 and 5001 in the EC2 Security
#       Group, and fill in the .env with the real DB values.
# ============================================================================
set -euo pipefail

REPO_URL="https://github.com/Villa19d/Iot_carrito_aws_backend.git"
BRANCH="feat/portfolio-demo"
APP_DIR="/home/ec2-user/Carrito_backend"
WS_DIR="$APP_DIR/TestingAPIWebsockets/WebSockets"
SERVICE="carrito-api"
UNIT="/etc/systemd/system/${SERVICE}.service"

# ---------------------------------------------------------------------------
echo "==> [1/7] Updating system and installing git, python3.11, python3.11-pip"
sudo dnf update -y
sudo dnf install -y git python3.11 python3.11-pip || sudo dnf install -y git python3.11

# ---------------------------------------------------------------------------
echo "==> [2/7] Cloning repository (branch: $BRANCH)"
cd /home/ec2-user
if [ -d "$APP_DIR/.git" ]; then
  git -C "$APP_DIR" fetch origin
  git -C "$APP_DIR" checkout "$BRANCH"
  git -C "$APP_DIR" pull origin "$BRANCH"
else
  git clone -b "$BRANCH" "$REPO_URL" "$APP_DIR"
fi

# Make sure the whole app tree is owned by ec2-user. A previous run done with
# `sudo` can leave root-owned files, which breaks `rm -rf venv` and writing.
sudo chown -R ec2-user:ec2-user "$APP_DIR"

# ---------------------------------------------------------------------------
echo "==> [3/7] Entering $WS_DIR"
cd "$WS_DIR"

# ---------------------------------------------------------------------------
echo "==> [4/7] Creating and activating virtualenv (Python 3.11)"
# Recreate the venv so a previously-created 3.9 venv is not reused.
if [ -d venv ]; then rm -rf venv; fi
python3.11 -m venv venv
# shellcheck disable=SC1091
source venv/bin/activate

# ---------------------------------------------------------------------------
echo "==> [5/7] Installing dependencies"
REQ="requirements.txt"
# requirements.txt is currently stored as UTF-16; pip needs UTF-8.
if python -c "import sys; d=open('requirements.txt','rb').read(); sys.exit(0 if d[:2] in (b'\xff\xfe', b'\xfe\xff') else 1)"; then
  echo "    requirements.txt is UTF-16 -> converting to requirements.utf8.txt"
  python -c "open('requirements.utf8.txt','w',encoding='utf-8').write(open('requirements.txt','rb').read().decode('utf-16'))"
  REQ="requirements.utf8.txt"
fi
pip install --upgrade pip
pip install -r "$REQ"

# ---------------------------------------------------------------------------
echo "==> [5b] Ensuring .env exists"
if [ ! -f .env ]; then
  # NOTE: .env.example lives at the REPOSITORY ROOT, not next to the backend.
  if [ -f "$APP_DIR/.env.example" ]; then
    cp "$APP_DIR/.env.example" .env
    echo "    WARNING: .env was created from $APP_DIR/.env.example (empty values)."
    echo "             Fill in DB_HOST/DB_USER/DB_PASSWORD/DB_NAME/... then run:"
    echo "             sudo systemctl restart $SERVICE"
  else
    echo "    WARNING: no .env found. Create one in $WS_DIR before starting the service."
  fi
fi

# ---------------------------------------------------------------------------
echo "==> [6/7] Writing systemd unit $UNIT"
sudo tee "$UNIT" >/dev/null <<EOF
[Unit]
Description=Carrito IoT backend (Flask REST + native WebSocket)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=ec2-user
Group=ec2-user
WorkingDirectory=$WS_DIR
EnvironmentFile=-$WS_DIR/.env
ExecStart=$WS_DIR/venv/bin/python $WS_DIR/server_final.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# ---------------------------------------------------------------------------
echo "==> [7/7] Enabling and starting $SERVICE"
sudo systemctl daemon-reload
sudo systemctl enable --now "$SERVICE"
sudo systemctl status "$SERVICE" --no-pager || true

echo
echo "DONE."
echo "  REST -> http://<EC2_PUBLIC_IP>:5001/api   (open port 5001 in the Security Group)"
echo "  WS   -> ws://<EC2_PUBLIC_IP>:5000         (open port 5000 in the Security Group)"
echo "  Logs -> sudo journalctl -u $SERVICE -f"
