#cloud-config
write_files:
  - path: /etc/todo-app/env
    owner: root:root
    permissions: "0600"
    content: |
      APP_ENV=${app_env}
      BG_COLOR=lightblue
      DB_HOST=${db_host}
      DB_PORT=5432
      DB_NAME=${db_name}
      DB_USER=${db_user}
      DB_PASSWORD=${db_password}
      DB_SSLMODE=prefer

runcmd:
  - systemctl restart todo-app.service
