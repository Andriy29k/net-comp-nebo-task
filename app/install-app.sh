#!/binbash

set -euo pipefail

APP_ROOT="/opt/todo-app"
REPOSITORY="https://github.com/Andriy29k/net-comp-nebo-task.git" 

sudo apt-get update
sudo apt-get install -y python3-venv python3-pip

sudo useradd --system --home "$APP_ROOT" --shell /usr/sbin/nologin todoapp 2>/dev/null || true

git clone "$REPOSITORY" /tmp/todo-app
sudo cp -r /tmp/todo-app/* "$APP_ROOT/"

sudo cp "$APP_ROOT/app/todo-app.service" /etc/systemd/system/todo-app.service

sudo python3 -m venv "$APP_ROOT/app/venv"
sudo "$APP_ROOT/app/venv/bin/pip" install --no-cache-dir -r "$APP_ROOT/app/requirements.txt"

sudo chown -R todoapp:todoapp "$APP_ROOT"
sudo chmod 700 /etc/todo-app

if [[ ! -f /etc/todo-app/env ]]; then
  sudo cp "$(dirname "$0")/todo-app.env.example" /etc/todo-app/env
  sudo chmod 600 /etc/todo-app/env
  sudo chown root:root /etc/todo-app/env
fi

sudo systemctl daemon-reload
sudo systemctl enable todo-app
sudo systemctl start todo-app