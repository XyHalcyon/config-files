#!/usr/bin/env python3
"""Validate all model configurations in Hermes config.yaml against provider APIs.

Usage: Run via execute_code or directly on the host.
Outputs a summary table of each model's reachability.
"""
import os
import sys
import json
import urllib.request
import urllib.error
import yaml  # requires PyYAML

HERMES_HOME = os.environ.get("HERMES_HOME", os.path.expanduser("~/.hermes"))
# Windows fallback
if not os.path.exists(HERMES_HOME):
    win_home = os.path.join(os.environ.get("USERPROFILE", ""), "AppData", "Local", "hermes")
    if os.path.exists(win_home):
        HERMES_HOME = win_home

CONFIG_PATH = os.path.join(HERMES_HOME, "config.yaml")
ENV_PATH = os.path.join(HERMES_HOME, ".env")

DEFAULT_ENDPOINTS = {
    "dashscope": "https://dashscope.aliyuncs.com/compatible-mode/v1",
    "deepseek": "https://api.deepseek.com/v1",
    "openrouter": "https://openrouter.ai/api/v1",
    "openai": "https://api.openai.com/v1",
    "anthropic": "https://api.anthropic.com/v1",
    "xai": "https://api.x.ai/v1",
}

API_KEY_ENV = {
    "dashscope": "DASHSCOPE_API_KEY",
    "deepseek": "DEEPSEEK_API_KEY",
    "openrouter": "OPENROUTER_API_KEY",
    "openai": "OPENAI_API_KEY",
    "anthropic": "ANTHROPIC_API_KEY",
    "xai": "XAI_API_KEY",
}


def load_env_keys():
    """Load API keys from .env file and environment."""
    keys = {}
    # From environment first
    for provider, env_var in API_KEY_ENV.items():
        v = os.environ.get(env_var, "")
        if v:
            keys[provider] = v
    # Override/extend from .env
    if os.path.exists(ENV_PATH):
        with open(ENV_PATH, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if "=" in line and not line.startswith("#"):
                    key, _, value = line.partition("=")
                    key = key.strip()
                    value = value.strip().strip("'\"")
                    for provider, env_var in API_KEY_ENV.items():
                        if key == env_var:
                            keys[provider] = value
    return keys


def test_model(base_url, api_key, model_id, timeout=30):
    """Test a model via OpenAI-compatible /chat/completions."""
    url = f"{base_url.rstrip('/')}/chat/completions"
    payload = json.dumps({
        "model": model_id,
        "messages": [{"role": "user", "content": "Say hello in one word."}],
        "max_tokens": 20,
    }).encode("utf-8")

    req = urllib.request.Request(url, data=payload, method="POST")
    req.add_header("Content-Type", "application/json")
    req.add_header("Authorization", f"Bearer {api_key}")

    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            reply = data["choices"][0]["message"]["content"].strip()
            model_used = data.get("model", model_id)
            tokens = data.get("usage", {})
            return {
                "status": "OK",
                "reply": reply[:80],
                "model_returned": model_used,
                "tokens": tokens,
            }
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")[:300]
        try:
            err = json.loads(body)
            msg = err.get("error", {}).get("message", body)
        except Exception:
            msg = body
        return {"status": f"HTTP {e.code}", "error": msg[:200]}
    except Exception as e:
        return {"status": "ERROR", "error": str(e)[:200]}


def extract_models(config):
    """Extract all explicitly configured model+provider+base_url tuples."""
    models = []

    # Main model
    mc = config.get("model", {})
    if mc.get("default"):
        models.append({
            "role": "Main model",
            "model": mc["default"],
            "provider": mc.get("provider", ""),
            "base_url": mc.get("base_url", ""),
        })

    # Delegation model
    dc = config.get("delegation", {})
    if dc.get("model") and dc.get("model") != "auto":
        models.append({
            "role": "Delegation (sub-agent)",
            "model": dc["model"],
            "provider": dc.get("provider", ""),
            "base_url": dc.get("base_url", ""),
        })

    # Auxiliary models
    aux = config.get("auxiliary", {})
    for role, cfg in aux.items():
        if isinstance(cfg, dict):
            m = cfg.get("model", "")
            p = cfg.get("provider", "auto")
            if m and p != "auto" and m != "":
                models.append({
                    "role": f"Auxiliary.{role}",
                    "model": m,
                    "provider": p,
                    "base_url": cfg.get("base_url", ""),
                })

    # X search model
    xs = config.get("x_search", {})
    if xs.get("model"):
        models.append({
            "role": "X Search",
            "model": xs["model"],
            "provider": "xai",
            "base_url": "",
        })

    return models


def main():
    print(f"Hermes Home: {HERMES_HOME}")
    print(f"Config:      {CONFIG_PATH}")
    print()

    if not os.path.exists(CONFIG_PATH):
        print(f"ERROR: Config not found at {CONFIG_PATH}")
        sys.exit(1)

    with open(CONFIG_PATH, "r", encoding="utf-8") as f:
        config = yaml.safe_load(f)

    api_keys = load_env_keys()
    models = extract_models(config)

    if not models:
        print("No explicitly configured models found (all auto?)")
        return

    print(f"Found {len(models)} explicitly configured model(s):\n")
    print(f"{'Role':<30} {'Model':<25} {'Provider':<12} {'Status'}")
    print("-" * 90)

    for entry in models:
        role = entry["role"]
        model_id = entry["model"]
        provider = entry["provider"]
        base_url = entry["base_url"] or DEFAULT_ENDPOINTS.get(provider, "")

        api_key = api_keys.get(provider, "")
        if not api_key:
            print(f"{role:<30} {model_id:<25} {provider:<12} ⚠️  No API key ({API_KEY_ENV.get(provider, '?')})")
            continue

        if not base_url:
            print(f"{role:<30} {model_id:<25} {provider:<12} ⚠️  No base URL")
            continue

        result = test_model(base_url, api_key, model_id)
        status = "✅" if result["status"] == "OK" else "❌"
        detail = result.get("reply", result.get("error", ""))[:40]
        print(f"{role:<30} {model_id:<25} {provider:<12} {status} {result['status']}")
        if result["status"] != "OK":
            print(f"{'':>30} Error: {result.get('error', '')[:100]}")

    print("\nDone.")


if __name__ == "__main__":
    main()
