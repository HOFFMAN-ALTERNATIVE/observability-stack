# 0002. Keep the Telegram token out of the Alertmanager config

Status: accepted
Date: 2026-10-17

## Context
Alerts go to Telegram, which needs a bot token. Alertmanager does not expand
environment variables in its config file, and the config directory is committed to
git and mounted read-only.

## Options
1. Put the token in `alertmanager.yml`: simplest, but every user has to keep a
   modified, secret-bearing copy of a tracked file, and one careless commit leaks it.
2. Docker secrets: clean, but needs swarm mode or extra compose setup that most
   single-host users do not have.
3. A small entrypoint writes `$TELEGRAM_BOT_TOKEN` to a private file and Alertmanager
   reads it through `bot_token_file`. The chat id, which is not secret, is substituted
   with `sed` into a copy of the config.

## Decision
Option 3. The token stays in `.env` and never reaches a tracked file.

## Consequences
- `entrypoint.sh` uses `umask 077`, so the token file is readable only by the process.
- The image entrypoint is replaced, so an Alertmanager upgrade must keep the same
  binary path. CI runs `amtool check-config` and `shellcheck` on the script.
- Without a token the file contains `disabled` and sends fail. The stack still starts.
- Revisit if Alertmanager adds environment expansion for secrets.
