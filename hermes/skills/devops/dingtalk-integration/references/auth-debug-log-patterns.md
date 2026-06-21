# DingTalk Authorization Debug Log Patterns

## Symptom: Messages received but no response

Gateway log shows thinking emoji but no agent processing:

```
INFO gateway.platforms.dingtalk: [Dingtalk] _send_emotion: reply 🤔Thinking on msg=msgXXX
```

No "inbound message" or "response ready" lines follow.

## Root Cause: Layer 1 passes, Layer 2 blocks

The DingTalk platform adapter (Layer 1) validates the sender and sends the thinking emoji acknowledgment. But the gateway authorization (Layer 2) rejects the user because `DINGTALK_ALLOWED_USERS` contains `staff_id` (which Layer 1 accepts) but NOT `sender_id` (which Layer 2 requires).

### Layer 2 rejection log pattern:

```
WARNING gateway.run: Unauthorized user: $:LWCP_v1:$JZ8NL6bbZPgbfP6JaQAJ9+8vRRhz2wmb (张鑫) on dingtalk
```

## Resolution: Use wildcard to discover actual sender_id

1. Set `DINGTALK_ALLOWED_USERS=*` in `.env`
2. Restart gateway
3. Send test message on DingTalk
4. Read `sessions.json` to find the `origin.user_id`

### Successful flow after fix:

```
INFO gateway.run: inbound message: platform=dingtalk user=张鑫 msg='hi'
INFO gateway.platforms.dingtalk: [Dingtalk] _send_emotion: reply 🤔Thinking
INFO gateway.run: response ready: platform=dingtalk time=10.4s api_calls=1 response=17 chars
INFO gateway.platforms.dingtalk: [Dingtalk] _send_emotion: reply 🥳Done
```

## sessions.json origin block example

```json
"origin": {
  "platform": "dingtalk",
  "chat_id": "cidU0oU7FtsjfXCoHkSwOPoFWkkYOg+2dJadGQ9QKGSN5Y=",
  "chat_type": "dm",
  "user_id": "$:LWCP_v1:$JZ8NL6bbZPgbfP6JaQAJ9+8vRRhz2wmb",
  "user_name": "张鑫",
  "user_id_alt": "020838594649792907"
}
```

Key: `user_id` (= `sender_id`) is what `DINGTALK_ALLOWED_USERS` must contain for Layer 2 to pass.
