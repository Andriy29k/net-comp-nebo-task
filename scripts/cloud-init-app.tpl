#cloud-config
write_files:
  - path: /etc/todo-app/env
    owner: root:root
    permissions: "0600"
    content: |
      APP_ENV=${app_env}
      BG_COLOR=${bg_color}
      PORT=${port}
      DB_HOST=${db_host}
      DB_PORT=${db_port}
      DB_NAME=${db_name}
      DB_USER=${db_user}
      DB_PASSWORD=${db_password}
      DB_SSLMODE=${db_sslmode}

runcmd:
  - systemctl enable todo-app.service
  - systemctl start todo-app.service