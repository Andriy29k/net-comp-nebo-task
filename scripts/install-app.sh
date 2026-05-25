#!/bin/bash
set -euo pipefail

REPO_ROOT="/opt/todo-app"
APP_DIR="$REPO_ROOT/app"
VENV_DIR="$REPO_ROOT/venv"
REPO_URL="https://github.com/Andriy29k/net-comp-nebo-task.git"

sudo apt-get update
sudo apt-get install -y git python3-pip python3-venv

if [[ -d "$REPO_ROOT/.git" ]]; then
  cd "$REPO_ROOT" && sudo git pull origin main
else
  sudo mkdir -p "$REPO_ROOT"
  sudo git clone "$REPO_URL" "$REPO_ROOT"
fi

id -u todoapp &>/dev/null || sudo adduser --disabled-password --gecos "" todoapp

sudo python3 -m venv "$VENV_DIR"
sudo "$VENV_DIR/bin/pip" install -r "$APP_DIR/requirements.txt"

sudo mkdir -p /etc/todo-app
[[ -f /etc/todo-app/env ]] || sudo cp "$APP_DIR/todo-app.env.example" /etc/todo-app/env

sudo chown -R todoapp:todoapp "$REPO_ROOT"

sudo cp "$APP_DIR/todo-app.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable todo-app.service

echo "App setup complete."