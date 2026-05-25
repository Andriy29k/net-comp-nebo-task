#!/bin/bash
set -euo pipefail

APP_HOME="/opt/todo-app/app"
REPO_URL="https://github.com/Andriy29k/net-comp-nebo-task.git"

sudo apt-get update
sudo apt-get install -y git python3-pip python3-venv

if [[ -d "$APP_HOME/.git" ]]; then
  cd "$APP_HOME" && git pull origin main
else
  sudo mkdir -p "$APP_HOME"
  git clone "$REPO_URL" "$APP_HOME"
fi

id -u todoapp &>/dev/null || sudo adduser --disabled-password --gecos "" todoapp

python3 -m venv "$APP_HOME/venv"
"$APP_HOME/venv/bin/pip" install -r "$APP_HOME/app/requirements.txt"

sudo mkdir -p /etc/todo-app
[[ -f /etc/todo-app/env ]] || sudo cp "$APP_HOME/app/todo-app.env.example" /etc/todo-app/env

sudo chown -R todoapp:todoapp "$APP_HOME"

sudo cp "$APP_HOME/app/todo-app.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now todo-app.service

echo "App setup complete. Service 'todo-app' is running."