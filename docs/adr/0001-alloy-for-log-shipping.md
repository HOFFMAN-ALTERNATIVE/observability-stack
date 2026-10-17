# 0001. Ship logs with Grafana Alloy, not Promtail

Status: accepted
Date: 2026-10-17

## Context
The stack needs container logs and a few host log files (syslog, auth, nginx) in Loki,
labelled by container and compose service. Promtail used to be the default agent for
Loki, but Grafana has put it on end-of-life and named Alloy as its successor. A new
stack built on an agent that is already end-of-life starts with a migration on its list.

## Options
1. Promtail: smallest config, most examples online. End-of-life, so no future fixes.
2. Grafana Alloy: supported successor, same Loki pipeline stages, can also scrape
   metrics later. Config is a new language (River) and the image is larger.
3. Vector or Fluent Bit: mature and fast, but one more vendor and their Loki sinks
   need their own label mapping.

## Decision
Option 2. It is the supported path for Loki and keeps the agent from the same vendor
as the rest of the log pipeline.

## Consequences
- Docker discovery, relabelling and level extraction live in one file, `alloy/config.alloy`.
- CI runs `alloy fmt` on the config, so a syntax error fails the build.
- Alloy reads the Docker socket read-only. That is host-level access and is listed in
  the README limits.
- Revisit if Alloy should also take over metric scraping from Prometheus.
