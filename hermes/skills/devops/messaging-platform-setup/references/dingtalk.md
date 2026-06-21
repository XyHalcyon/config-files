# DingTalk (钉钉) Configuration

## Platform Setup

1. Go to [DingTalk Open Platform](https://open.dingtalk.com/)
2. Create a bot application
3. Obtain **Client ID** (AppKey) and **Client Secret** (AppSecret)

## Connection Mode

DingTalk supports two message-receiving modes:

| Mode | Requires Public IP | Best For |
|------|-------------------|----------|
| **Stream** | No | Local/home deployments |
| HTTP | Yes (callback URL + HTTPS) | Cloud/server deployments |

**Choose Stream mode** for local Windows/macOS/Linux machines. It uses a long-lived outbound WebSocket connection — Gateway connects to DingTalk's server, so no inbound port forwarding is needed.

## Env Vars

After running `hermes gateway setup` and choosing DingTalk:

```bash
DINGTALK_CLIENT_ID=dingxxxxxxxxxxxxx
DINGTALK_CLIENT_SECRET=your_secret_here
```

### User Allowlist

```bash
# Allow specific DingTalk user IDs (comma-separated)
DINGTALK_ALLOWED_USERS=198_zae1rqkus7

# Or allow all users (less secure)
# GATEWAY_ALLOW_ALL_USERS=true
```

## Verification

After restart, check gateway logs for:

```
[Dingtalk] Robot SDK initialized (media download)
[Dingtalk] Connected via Stream Mode
✓ dingtalk connected
Gateway running with 1 platform(s)
```

The "No user allowlists configured" warning should be **absent** if `DINGTALK_ALLOWED_USERS` is set.

## Restart Command

```bash
hermes gateway restart
```

`.env` changes require a gateway restart — they are not hot-reloaded.

## Logs Path

```
%HERMES_HOME%\logs\gateway.log
```

On Windows with default install: `C:\Users\<user>\AppData\Local\hermes\logs\gateway.log`
