---
name: messaging-platform-setup
description: "Configure Hermes Gateway messaging platforms (DingTalk, Telegram, Discord, etc.) — setup wizards, credential placement, allowlists, and verification."
version: 1.0.0
author: agent
tags: [gateway, messaging, platforms, dingtalk, telegram, discord, setup]
---

# Messaging Platform Setup

Configure any messaging platform on Hermes Gateway. Covers the general pattern — interactive wizard, credential placement in `.env`, allowlist enforcement, and restart verification.

## When to Use

- User wants to connect a new messaging platform (DingTalk, Telegram, Discord, Slack, WeCom, Feishu, etc.)
- Gateway is running but messages aren't delivering
- "No user allowlists configured" warning appears in gateway logs

## General Workflow

### 1. Prepare Platform Credentials

Create an app/bot on the target platform's developer console and obtain:
- App ID / Client ID / Bot Token
- App Secret / Client Secret
- Any platform-specific keys

### 2. Run Interactive Setup Wizard

```bash
hermes gateway setup
```

Select the target platform, choose the connection mode (Stream vs HTTP for platforms that offer both), and paste credentials.

### 3. Verify Credentials in .env

Credentials are written to `$HERMES_HOME/.env`. After the wizard, verify:

```bash
# Windows
type %HERMES_HOME%\.env | findstr /i <PLATFORM>

# Linux/macOS
grep -i <PLATFORM> $HERMES_HOME/.env
```

### 4. Configure User Allowlist

By default, the gateway **denies all users** unless an allowlist is configured. You have two options:

**Option A — Allow specific users (recommended):**
Add to `.env`:
```
<PLATFORM>_ALLOWED_USERS=user_id1,user_id2
```

**Option B — Allow all users (open access):**
Add to `.env`:
```
GATEWAY_ALLOW_ALL_USERS=true
```

### 5. Restart Gateway

```bash
hermes gateway restart
```

The gateway must restart to pick up `.env` changes.

### 6. Verify Connection

```bash
# Check status
hermes gateway status

# Check logs for connection confirmation
# Windows: type %HERMES_HOME%\logs\gateway.log
# Linux:   tail -50 $HERMES_HOME/logs/gateway.log
```

Look for:
```
✓ <platform> connected
Gateway running with 1 platform(s)
```

And confirm the allowlist warning is **gone** (it appears at startup if no users are allowed).

### 7. Test

Send a message from the platform client to the bot. If no response, check logs:

```bash
# Windows
type %HERMES_HOME%\logs\gateway.log | findstr /i error

# Linux
grep -i error $HERMES_HOME/logs/gateway.log
```

## Pitfalls

- **`.env` changes need a restart.** The gateway only reads `.env` at startup. Use `hermes gateway restart`, not just `hermes gateway start`.
- **`hermes config` doesn't show all platforms.** The `hermes config` summary only lists a subset of configured platforms. Read the actual `config.yaml` or check gateway logs for the full picture.
- **Allowlist warning = silent rejection.** If you see "No user allowlists configured" in gateway logs, ALL users are being denied. Messages will appear to send but never reach the agent.
- **Stream vs HTTP for platforms that support both (DingTalk, Feishu, etc.):** Choose **Stream** when running on a local machine without public IP. Stream mode uses a long-lived outbound connection from Gateway to the platform server, so no inbound port forwarding is needed.

## Platform-Specific References

- [DingTalk](references/dingtalk.md) — Stream mode, env vars, allowlist, verification
