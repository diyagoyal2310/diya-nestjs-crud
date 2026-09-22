#!/usr/bin/env bash
set -euo pipefail

readonly APP_DIR=/home/ubuntu/diya-nestjs-crud
readonly APP_USER=ubuntu
readonly DEPLOY_BRANCH=new-setup
readonly SERVICE_NAME=diya-nestjs-crud.service

find_node_bin() {
  local candidate

  if [[ -s /home/ubuntu/.nvm/nvm.sh ]]; then
    candidate="$(runuser -u "$APP_USER" -- bash -lc '. /home/ubuntu/.nvm/nvm.sh && command -v node || true')"
    if [[ -n "$candidate" && -x "$candidate" ]]; then
      readlink -f "$candidate"
      return
    fi
  fi

  candidate="$(runuser -u "$APP_USER" -- bash -lc 'command -v node || true')"
  if [[ -n "$candidate" && -x "$candidate" ]]; then
    readlink -f "$candidate"
    return
  fi

  for candidate in /usr/bin/node /usr/local/bin/node; do
    if [[ -x "$candidate" ]]; then
      readlink -f "$candidate"
      return
    fi
  done

  candidate="$(find /home/ubuntu/.nvm/versions/node -type f -path '*/bin/node' -print 2>/dev/null | sort -V | tail -n 1 || true)"
  if [[ -n "$candidate" && -x "$candidate" ]]; then
    readlink -f "$candidate"
    return
  fi

  return 1
}

if [[ "$(id -u)" -ne 0 ]]; then
  echo 'This deployment script must be run by root (as AWS SSM does).' >&2
  exit 1
fi

if [[ ! -d "$APP_DIR/.git" ]]; then
  echo "Expected Git repository not found: $APP_DIR" >&2
  exit 1
fi

cd "$APP_DIR"

NODE_BIN="$(find_node_bin)" || {
  echo 'Node.js was not found for the ubuntu user or in a supported system location.' >&2
  exit 1
}
NODE_DIR="$(dirname "$NODE_BIN")"
NPM_BIN="$NODE_DIR/npm"

if [[ ! -x "$NPM_BIN" ]]; then
  echo "npm matching Node.js was not found: $NPM_BIN" >&2
  exit 1
fi

if [[ ! -f "$APP_DIR/.env" ]]; then
  echo "Expected existing environment file not found: $APP_DIR/.env" >&2
  exit 1
fi

echo "Deploying branch $DEPLOY_BRANCH as $APP_USER"
echo "Using Node.js: $NODE_BIN ($($NODE_BIN --version))"

run_as_app_user() {
  runuser -u "$APP_USER" -- env HOME=/home/ubuntu PATH="$NODE_DIR:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" "$@"
}

run_as_app_user git config --global --add safe.directory "$APP_DIR"
run_as_app_user git -C "$APP_DIR" fetch origin "$DEPLOY_BRANCH"
run_as_app_user git -C "$APP_DIR" checkout "$DEPLOY_BRANCH"
run_as_app_user git -C "$APP_DIR" pull --ff-only origin "$DEPLOY_BRANCH"
run_as_app_user "$NPM_BIN" ci
run_as_app_user "$NPM_BIN" run build

install -d -m 0755 /etc/systemd/system
cat >"/etc/systemd/system/$SERVICE_NAME" <<EOF
[Unit]
Description=Diya NestJS CRUD application
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$APP_USER
WorkingDirectory=$APP_DIR
Environment=NODE_ENV=production
ExecStart=$NODE_BIN $APP_DIR/dist/main.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl restart "$SERVICE_NAME"
systemctl is-active --quiet "$SERVICE_NAME"

echo "Deployment complete. $SERVICE_NAME is active."
