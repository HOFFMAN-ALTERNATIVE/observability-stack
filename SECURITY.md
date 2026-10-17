# Security

## Reporting

Use GitHub's private "Report a vulnerability" button on this repository. I aim to reply within 72 hours.

## Threat model

- **Assets:** host metrics and logs (auth logs included), the Grafana admin account, the Telegram bot token.
- **Actors:** anyone who can reach the host's ports, and any compromised container on the host.
- **Entry points:** published ports, the Docker socket, log contents shipped to Loki.
- **Defaults that matter:** every port binds to `127.0.0.1` unless `BIND_ADDR` is changed; Grafana sign-up and anonymous access are off and an admin password is required; the Telegram token is read from the environment, never written into config files; all images are pinned to versions; `no-new-privileges` on every service; log rotation on every container.
- **Known high-privilege pieces:** cAdvisor runs privileged and Alloy mounts the Docker socket read-only. Read-only on the socket does not limit the Docker API, so treat Alloy as root-equivalent.

## Not provided

- TLS and authentication in front of Prometheus, Alertmanager and Loki. Keep them on localhost or put them behind an authenticating reverse proxy.
- Redaction of secrets that applications write to their own logs.
