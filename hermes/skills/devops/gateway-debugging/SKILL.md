---
name: gateway-debugging
description: "Debug Hermes Gateway messaging platforms: silent message drops, allowlist mismatches, connection issues."
version: 1.0.0
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [gateway, debugging, messaging, dingtalk, telegram, discord, allowlist]
---

# Gateway Messaging Platform Debugging

Debug Hermes Gateway when messages arrive on a platform but the agent never processes them — no response, no error in logs, just silence after the thinking/reaction emoji.

## Trigger

- User sends a message on a configured Gateway platform (DingTalk, Telegram, Discord, etc.)
- Gateway logs show the inbound message acknowledged (thinking emoji, reaction) but NO agent run follows
- No "denied" or "blocked" visible in gateway.log at INFO level

## Root Cause: Allowlist Mismatch (Silent Drop)

The most common cause is an **allowlist mismatch**. The platform adapter receives the message, checks `_is_user_allowed()`, and if it fails, drops the message — but logs at **DEBUG level**, which is invisible in default INFO logging.

The user-provided ID (e.g. a DingTalk staff number like `198_zae1rqkus7`) often does NOT match the actual `sender_id` or `sender_staff_id` field in the platform's message payload.

## Diagnostic Workflow

### Step 1: Confirm the symptom

```bash
hermes gateway status          # confirm running
# Check logs for "inbound message" vs "response ready"
findstr /i "inbound response ready denied" %HERMES_HOME%\logs\gateway.log
```

If you see "inbound message" but no matching "response ready" or "agent run", and no "denied" visible → likely an allowlist drop.

### Step 2: Temporarily open the allowlist

Edit `%HERMES_HOME%\.env` and set the platform's allowlist to wildcard:

```
DINGTALK_ALLOWED_USERS=*
# or TELEGRAM_ALLOWED_USERS=*
# or DISCORD_ALLOWED_USERS=*
```

Restart the gateway:

```bash
hermes gateway restart
```

### Step 3: Send a test message and capture the real ID

Have the user send a test message. Wait ~5 seconds, then read the routing metadata:

**On Windows (Hermes Home under AppData):**
```
%HERMES_HOME%\sessions\sessions.json
```

**On Linux/macOS:**
```
~/.hermes/sessions/sessions.json
```

Each entry's `origin` block contains the real IDs:

```json
{
  "origin": {
    "platform": "dingtalk",
    "user_id": "$:LWCP_v1:$JZ8NL6bbZPgbfP6JaQAJ9+8vRRhz2wmb",
    "user_name": "张鑫",
    "user_id_alt": "020838594649792907"
  }
}
```

### Step 4: Set the precise allowlist

Use either `user_id` or `user_id_alt` (the adapter checks both). Restore the `.env`:

```
DINGTALK_ALLOWED_USERS=020838594649792907
```

Restart:

```bash
hermes gateway restart
```

### Step 5: Verify

Send another test message. Logs should now show:

```
inbound message: platform=dingtalk user=XXX msg='test'
response ready: platform=dingtalk ... response=N chars
```

## Platform-Specific Notes

### DingTalk
- `sender_id` often looks like `$:LWCP_v1:$<base64>` — NOT the user's visible staff number
- `sender_staff_id` (in `user_id_alt`) is a numeric string — more stable, preferred for allowlist
- Stream mode does NOT require a public URL; HTTP callback mode does
- The allowlist is enforced in `gateway/platforms/dingtalk.py::_is_user_allowed()`, logged at `logger.debug()` — invisible at INFO

### General
- All platform adapters follow the same pattern: message received → allowlist check → agent run
- If the allowlist blocks, the drop is logged at DEBUG level across all adapters
- `sessions.json` is the canonical source for real user/channel IDs after a successful message
- `GATEWAY_ALLOW_ALL_USERS=true` is a global bypass but opens access to ALL platforms

## Reference Files

- `references/dingtalk-allowlist-debug.md` — Full session transcript: DingTalk silent-drop diagnosis, real IDs captured, source code reference.

## Pitfalls

- **DEBUG-level drop logging**: The `_is_user_allowed` rejection is logged at DEBUG, not WARNING or INFO. You will NOT see it in default logs. Don't assume no drop just because no "denied" appears.
- **ID format mismatch**: The ID visible in the platform UI (staff number, username, handle) often differs from the `sender_id` in the message payload. Always extract from `sessions.json` after a wildcard test.
- **Restart required**: `.env` changes require a gateway restart (`hermes gateway restart`), not just a `/reset` in chat.
- **Don't leave wildcard**: After capturing the real ID, immediately restore the precise allowlist. `*` leaves your agent open to anyone on that platform.
