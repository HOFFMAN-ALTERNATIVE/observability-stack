#!/usr/bin/env bash
# shellcheck disable=SC2015  # pass() always succeeds, so A && pass || fail is safe
# End-to-end smoke test of a running stack: health, scrape targets, provisioning, log ingestion, alert routing.
set -euo pipefail
PROM=${PROM:-http://127.0.0.1:9090}
AM=${AM:-http://127.0.0.1:9093}
GRAFANA=${GRAFANA:-http://127.0.0.1:3000}
LOKI=${LOKI:-http://127.0.0.1:3100}
GF_AUTH="${GRAFANA_ADMIN_USER:-admin}:${GRAFANA_ADMIN_PASSWORD:-change-me-please}"

pass() { printf '  \e[32m✔\e[0m %s\n' "$*"; }
fail() { printf '  \e[31m✘\e[0m %s\n' "$*"; exit 1; }

# wait_for URL [tries]
wait_for() {
  local i
  for ((i = 0; i < ${2:-60}; i++)); do curl -fsS -o /dev/null "$1" && return 0; sleep 2; done
  return 1
}

echo "== health"
wait_for "$PROM/-/ready" && pass prometheus || fail prometheus
wait_for "$AM/-/ready" && pass alertmanager || fail alertmanager
wait_for "$GRAFANA/api/health" && pass grafana || fail grafana
wait_for "$LOKI/ready" 90 && pass loki || fail loki

echo "== prometheus targets"
want="prometheus alertmanager node cadvisor loki grafana alloy"
for _ in $(seq 30); do
  down=$(curl -fsS "$PROM/api/v1/targets" | jq -r '[.data.activeTargets[] | select(.health != "up") | .labels.job] | join(" ")')
  total=$(curl -fsS "$PROM/api/v1/targets" | jq '.data.activeTargets | length')
  [[ -z "$down" && "$total" -ge 7 ]] && break
  sleep 3
done
[[ -z "$down" ]] || fail "targets not up: $down"
for j in $want; do
  curl -fsS "$PROM/api/v1/targets" | jq -e --arg j "$j" '.data.activeTargets[] | select(.labels.job == $j and .health == "up")' >/dev/null \
    && pass "target $j up" || fail "target $j"
done

echo "== rules"
n=$(curl -fsS "$PROM/api/v1/rules" | jq '[.data.groups[].rules[]] | length')
(( n >= 10 )) && pass "$n rules loaded" || fail "only $n rules"
curl -fsS "$PROM/api/v1/query?query=instance:node_memory_utilisation:ratio" | jq -e '.data.result | length > 0' >/dev/null \
  && pass "recording rule evaluates" || fail "recording rule empty"

echo "== grafana provisioning"
for ds in prometheus loki; do
  curl -fsS -u "$GF_AUTH" "$GRAFANA/api/datasources/uid/$ds/health" | jq -e '.status == "OK"' >/dev/null \
    && pass "datasource $ds healthy" || fail "datasource $ds"
done
curl -fsS -u "$GF_AUTH" "$GRAFANA/api/dashboards/uid/host-containers" | jq -e '.dashboard.panels | length >= 10' >/dev/null \
  && pass "dashboard provisioned" || fail "dashboard missing"

echo "== loki ingestion (via alloy)"
for _ in $(seq 40); do
  c=$(curl -fsS -G "$LOKI/loki/api/v1/query_range" --data-urlencode 'query={compose_project="observability"}' --data-urlencode 'limit=5' | jq '[.data.result[].values[]] | length')
  (( c > 0 )) && break
  sleep 3
done
(( c > 0 )) && pass "container logs in loki" || fail "no logs in loki"

echo "== alertmanager"
curl -fsS "$AM/api/v2/status" | jq -e '.config.original | contains("telegram_configs")' >/dev/null && pass "telegram receiver configured" || fail "receiver"
for _ in $(seq 20); do
  curl -fsS "$AM/api/v2/alerts" | jq -e '.[] | select(.labels.alertname == "Watchdog")' >/dev/null && break
  sleep 3
done
curl -fsS "$AM/api/v2/alerts" | jq -e '.[] | select(.labels.alertname == "Watchdog")' >/dev/null \
  && pass "Watchdog alert reached alertmanager" || fail "alert pipeline broken"

echo "All checks passed."
