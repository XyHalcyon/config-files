---
name: dingtalk-integration
description: Set up and troubleshoot Hermes Gateway DingTalk (钉钉) integration — Stream Mode configuration, authorization, and common pitfalls.
version: 1.0.0
platforms: [windows, linux, macos]
metadata:
  hermes:
    tags: [dingtalk, gateway, messaging, platform]
---

# DingTalk Integration

Set up DingTalk (钉钉) as a messaging platform for Hermes Agent via Stream Mode, and troubleshoot common authorization issues.

## Prerequisites

1. A DingTalk application on [open.dingtalk.com](https://open.dingtalk.com) with a bot
2. Credentials: **AppKey** (Client ID) and **AppSecret** (Client Secret)
3. Choose **Stream Mode** (长连接) for message reception — no public URL required

## Setup

```bash
# Interactive wizard — select DingTalk, enter AppKey/AppSecret, pick Stream Mode
hermes gateway setup

# Start the gateway
hermes gateway run        # foreground test
hermes gateway install    # Windows Scheduled Task / systemd service
hermes gateway start
```

## Authorization: Two-Layer Model (Critical)

DingTalk authorization has **two independent layers**. Both must pass for messages to reach the agent.

### Layer 1: Platform Adapter (`dingtalk.py`)

Checks BOTH `sender_id` AND `sender_staff_id` against `DINGTALK_ALLOWED_USERS`.
Set in `.env`:

```
DINGTALK_ALLOWED_USERS=<comma-separated IDs>
```

### Layer 2: Gateway Authorization (`authz_mixin.py`)

Checks ONLY `user_id` (= `sender_id`) against `DINGTALK_ALLOWED_USERS`.
Uses the **same env var** but a **different field**.

**Key mismatch**: The DingTalk `sender_id` (e.g. `$:LWCP_v1:$xxx`) is often different from the `staff_id` (e.g. `020838594649792907`) and from the user-facing 钉钉号 (e.g. `198_zae1rqkus7`). The gateway layer only checks `sender_id`, so `DINGTALK_ALLOWED_USERS` must include the `sender_id` value.

## Finding the Actual User ID

The user-facing 钉钉号 is NOT the `sender_id` used in Stream Mode messages. To discover the real IDs:

1. Temporarily set wildcard allowlist:
   ```
   DINGTALK_ALLOWED_USERS=*
   ```
2. Restart gateway: `hermes gateway restart`
3. Have the user send a test message on DingTalk
4. Check `~/.hermes/sessions/sessions.json` for the `origin` block:
   ```json
   "origin": {
     "user_id": "$:LWCP_v1:$JZ8NL6bbZPgbfP6JaQAJ9+8vRRhz2wmb",
     "user_name": "张鑫",
     "user_id_alt": "020838594649792907"
   }
   ```
5. Use the `user_id` value in `DINGTALK_ALLOWED_USERS`
6. Remove the wildcard and restart

## Gateway Runs as Background Service

On Windows, `hermes gateway install` registers a Scheduled Task (`Hermes_Gateway`). The gateway is independent of terminal windows — closing the CLI does NOT stop DingTalk message reception.

```bash
hermes gateway status    # Check if running
hermes gateway restart   # Restart after config changes
```

## Pitfalls

- **DINGTALK_ALLOWED_USERS=198_zae1rqkus7 won't work**: The 钉钉号 visible in the app UI is neither `sender_id` nor `staff_id` in Stream Mode. Always use the wildcard-discovery method above.
- **Messages silent after setup**: Check both layers. The gateway log shows "Unauthorized user" warnings when Layer 2 blocks. Platform-layer blocks are logged at DEBUG level (invisible by default).
- **Must restart gateway after `.env` changes**: `hermes gateway restart`
- **`user_id_alt` (staff_id) passes Layer 1 but fails Layer 2**: The gateway only checks `user_id`, not `user_id_alt`. Always use `user_id` (= `sender_id`) for `DINGTALK_ALLOWED_USERS`.
