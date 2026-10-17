# 0003. One Prometheus and one Loki on local volumes

Status: accepted
Date: 2026-10-17

## Context
The target is one server or a small fleet, run by one person or a small team. The
whole stack has to start with `docker compose up` and be checked end to end in CI on
a single GitHub runner.

## Options
1. Single Prometheus and Loki on Docker volumes, with retention limits: one command to
   start, nothing extra to operate. History is lost with the host.
2. Prometheus with Thanos or Mimir, Loki on S3-compatible storage: durable and
   scalable, but adds object storage, more containers and more config to keep in sync.
3. A hosted service: no storage to run, but recurring cost and data leaves the host.

## Decision
Option 1. For a few hosts the operational cost of option 2 is larger than the value
of keeping history after a total host loss.

## Consequences
- Prometheus keeps 15 days by default (`PROMETHEUS_RETENTION`), Loki keeps 7 days
  through the compactor. Disk use stays bounded.
- No HA. If the host dies, alerting from it dies too. The always-firing Watchdog alert
  is routed to a blackhole today; pointing it at an external dead-man's switch is
  the cheap fix and is left to the operator.
- Loki uses the TSDB index with schema v13, so moving to object storage later is a
  config change, not a re-index.
- Revisit when there are more hosts than one Prometheus can scrape comfortably, or
  when history must survive the host.
