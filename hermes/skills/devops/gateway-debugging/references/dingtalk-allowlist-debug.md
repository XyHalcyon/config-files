# DingTalk Allowlist Debug — Session Transcript

Session date: 2026-06-21
Platform: DingTalk Stream Mode

## Symptom

User sent messages on DingTalk. Gateway logs showed thinking emoji replies
(`_send_emotion: reply 🤔Thinking on msg=...`) but no agent processing.
No "denied" or "blocked" visible in default INFO-level logs.

## Root Cause

The user's DingTalk staff number (`198_zae1rqkus7`) did not match any of
the IDs in the Stream message payload. The `_is_user_allowed` check in
`gateway/platforms/dingtalk.py` failed silently at DEBUG log level.

## Diagnosis Logs

```
# Gateway acknowledged message but didn't process:
00:38:04 INFO [Dingtalk] _send_emotion: reply 🤔Thinking on msg=msgBSCBWZKHi1S9Wbbt7Z06M
00:38:23 INFO [Dingtalk] _send_emotion: reply 🤔Thinking on msg=msgxZwRc2oE7xyPasMczUFY0
00:38:54 INFO [Dingtalk] _send_emotion: reply 🤔Thinking on msg=msgGj6heg9cRcVkDOkae1Io6
# ← No agent run, no response, no error
```

## Wildcard Test (after DINGTALK_ALLOWED_USERS=*)

```
# Success — message processed:
00:42:07 inbound message: platform=dingtalk user=张鑫 msg='hi'
00:42:18 response ready: platform=dingtalk time=10.4s api_calls=1 response=17 chars
```

## Real IDs Extracted from sessions.json

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

## Fix

Set `DINGTALK_ALLOWED_USERS=020838594649792907` (the `sender_staff_id` /
`user_id_alt`, which is more stable than the base64 `user_id`).

## Relevant Source

`gateway/platforms/dingtalk.py` lines 608-614:
```python
# Allowed-users gate
if not self._is_user_allowed(sender_id, sender_staff_id):
    logger.debug(  # ← DEBUG only — invisible at default INFO
        "[%s] Dropping message from non-allowlisted user staff_id=%s sender_id=%s",
        ...
    )
    return  # Silent drop
```
