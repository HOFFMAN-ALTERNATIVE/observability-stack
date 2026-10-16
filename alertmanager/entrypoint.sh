#!/bin/sh
# Render runtime secrets, then exec Alertmanager.
set -eu
umask 077
printf '%s' "${TELEGRAM_BOT_TOKEN:-disabled}" > /tmp/telegram_token
sed "s/__TELEGRAM_CHAT_ID__/${TELEGRAM_CHAT_ID:-123456789}/" /etc/alertmanager/alertmanager.yml > /tmp/alertmanager.yml
exec /bin/alertmanager --config.file=/tmp/alertmanager.yml --storage.path=/alertmanager "$@"
