#!/bin/sh
# Render runtime secrets, then exec Alertmanager.
set -eu
umask 077
printf '%s' "${TELEGRAM_BOT_TOKEN:-disabled}" > /tmp/telegram_token

# Dead-man's switch: any service that alerts when periodic pings stop
# (healthchecks.io, Dead Man's Snitch, Cronitor, a self-hosted Healthchecks...).
dms_url="${DEADMANS_SWITCH_URL:-}"
case "$dms_url" in
  "") watchdog_receiver=blackhole ;;
  *[[:space:]]*) echo "DEADMANS_SWITCH_URL must not contain whitespace" >&2; exit 1 ;;
  https://* | http://*) watchdog_receiver=deadmans-switch ;;
  *) echo "DEADMANS_SWITCH_URL must start with https:// (or http:// on a private network)" >&2; exit 1 ;;
esac
printf '%s' "$dms_url" > /tmp/deadmans_switch_url

sed -e "s/__TELEGRAM_CHAT_ID__/${TELEGRAM_CHAT_ID:-123456789}/" \
  -e "s/__WATCHDOG_RECEIVER__/${watchdog_receiver}/" \
  /etc/alertmanager/alertmanager.yml > /tmp/alertmanager.yml
echo "watchdog receiver: ${watchdog_receiver}" >&2
exec /bin/alertmanager --config.file=/tmp/alertmanager.yml --storage.path=/alertmanager "$@"
