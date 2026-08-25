# GPT-5.6 context windows in Codex, Hermes, and pi

**Research date:** 2026-08-24

## Executive finding

Yes, pi can use the larger GPT-5.6 context budget when using the ChatGPT/Codex subscription provider. The setting belongs in pi's `~/.pi/agent/models.json`, under the built-in `openai-codex` provider. It is not inherited from `~/.codex/config.toml`.

Use the current Codex catalog maximum (`872000`) as the conservative pi value. `900000` is the rounded/empirical Hermes value, but it is above the `max_context_window` advertised by the locally installed Codex catalog and should be treated as an opt-in experiment, not the safe default.

## What the three tools mean by “context window”

| Surface | Relevant value | Meaning |
| --- | ---: | --- |
| OpenAI API model page | `1,050,000` | Published model capability for direct API GPT-5.6 Sol/Terra/Luna. |
| Codex catalog on this machine | `context_window=272000`, `max_context_window=872000` | Codex's default and maximum locally accepted session override. |
| Hermes large-context mode | about `900000` | Hermes-side context/compression budget, with the `-900k` model alias stripped before sending the base model ID. |
| pi's model metadata | `contextWindow` | Local budget used by pi and its compaction extensions; it does not send a `context_window` parameter to the Responses request. |

## Where the limit is enforced

The data flow is:

```text
pi contextWindow override
        │
        ├─ local: when pi compacts its transcript
        │
        └─ normal Responses request ──> ChatGPT/Codex backend
                                         │
                                         └─ server accepts or rejects the actual token count
```

Therefore, `contextWindow=872000` does **not** grant an entitlement and does not force OpenAI to accept 872K input. It only stops pi from compacting at 272K. If the backend for the account/session still enforces 272K, the request will fail with a context-length/overflow error; pi may recover by compacting and retrying, but the override itself cannot bypass the server.

The Codex CLI has a separate local guard: its `model_context_window` setting is clamped to the catalog's `max_context_window`. The current local catalog advertises `max_context_window=872000`, which is a strong signal that the current Codex route is intended to permit that override, but only a real request proves acceptance for a particular account/session. Hermes' roughly 900K figure is empirical evidence from its own live verification, not a server guarantee.

In this repository, pi's auto-compact extension is configured to compact at 80% of its model window. With an 872K override, that local trigger is about 698K, leaving headroom below both 872K and the Codex effective-window calculation. This improves safety but still does not turn local metadata into an entitlement.

Codex applies an additional `effective_context_window_percent=95`. Its source computes runtime context usage as the resolved window multiplied by that percentage. Codex also clamps `model_context_window` to the model's `max_context_window`, and clamps the automatic-compaction threshold to at most 90% of the resolved window.

## Evidence

### OpenAI model capability

OpenAI's first-party model pages list a `1,050,000` context window and `128,000` maximum output tokens for all three GPT-5.6 variants:

- [GPT-5.6 Sol](https://developers.openai.com/api/docs/models/gpt-5.6-sol)
- [GPT-5.6 Terra](https://developers.openai.com/api/docs/models/gpt-5.6-terra)
- [GPT-5.6 Luna](https://developers.openai.com/api/docs/models/gpt-5.6-luna)

Those pages also state that requests with more than 272K input tokens use the long-context price tier for the full request: 2x input and 1.5x output. The published model capability and the Codex subscription catalog are therefore separate limits.

### Codex configuration and source

The official [Codex configuration reference](https://developers.openai.com/codex/config-reference/) defines:

- `model_context_window`: context-window tokens available to the active model.
- `model_auto_compact_token_limit`: token threshold that triggers automatic history compaction.

The official [Codex configuration basics](https://developers.openai.com/codex/config-basic/) says the user-level file is `~/.codex/config.toml`; CLI overrides have higher precedence.

The current Codex source confirms the behavior:

- [`codex-rs/models-manager/src/model_info.rs`](https://github.com/openai/codex/blob/main/codex-rs/models-manager/src/model_info.rs) applies `min(model_context_window, max_context_window)` and stores the compaction override.
- [`codex-rs/models-manager/src/config.rs`](https://github.com/openai/codex/blob/main/codex-rs/models-manager/src/config.rs) defines both configuration fields.
- [`codex-rs/protocol/src/openai_models.rs`](https://github.com/openai/codex/blob/main/codex-rs/protocol/src/openai_models.rs) derives the automatic-compaction limit as no more than 90% of the resolved context window.
- [`codex-rs/core/src/session/turn_context.rs`](https://github.com/openai/codex/blob/main/codex-rs/core/src/session/turn_context.rs) computes the effective runtime context window using `effective_context_window_percent`.
- [Codex PR #39102](https://github.com/openai/codex/pull/39102) records the GPT-5.6 Sol/Terra/Luna maximum override as 872,000 tokens.

On this machine, `codex --version` reports `0.148.0`. Both `codex debug models --bundled` and `~/.codex/models_cache.json` report for Sol/Terra/Luna:

```text
context_window: 272000
max_context_window: 872000
effective_context_window_percent: 95
auto_compact_token_limit: null
```

Therefore, the often-circulated Codex configuration:

```toml
model_context_window = 1000000
model_auto_compact_token_limit = 900000
```

requests a larger budget, but the current catalog clamps the context window to 872,000. The compaction threshold is also subject to Codex's model-level clamp.

### Hermes behavior

The current [Hermes context-compression documentation](https://hermes-agent.nousresearch.com/docs/developer-guide/context-compression-and-caching) describes explicit `gpt-5.6-sol-900k`, `gpt-5.6-terra-900k`, and `gpt-5.6-luna-900k` picker variants. [Hermes PR #92797](https://github.com/NousResearch/hermes-agent/pull/92797) explains that the suffix is removed before the model ID is sent to the Codex backend; it is a Hermes-side metadata/compression variant, not a different OpenAI model or request header.

This likely explains the reported automatic change from 272K to 900K: an earlier Hermes change auto-raised the local Codex budget, while the current upstream design makes the large budget explicit because long requests consume subscription usage much faster. The Hermes documentation describes roughly 911K input tokens as empirically accepted for eligible ChatGPT-subscription accounts, but this remains account/backend behavior rather than a guarantee from the public model page.

The local checkout at `/Users/olisikh/Develop/hermes-agent` is older (`0.19.1`, commit `d467bf6ca`) and still has a 272K Codex fallback in `agent/model_metadata.py`; it does not represent the current upstream `-900k` implementation.

## pi configuration

The installed pi is `0.84.2`. Its [model documentation](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/models.md) says `models.json` can apply `modelOverrides` to built-in providers, supports `contextWindow`, and preserves the built-in pricing metadata. It explicitly documents a `1,050,000` override for direct OpenAI GPT-5.6 models.

This repository currently uses the subscription route:

- `defaultProvider = "openai-codex"`
- `defaultModel = "gpt-5.6-luna"`

See [`modules/home/ai/pi/default.nix`](../../modules/home/ai/pi/default.nix). The local pi catalog at `~/.pi/agent/models-store.json` identifies the three GPT-5.6 models as provider `openai-codex`, API `openai-codex-responses`, with `contextWindow=272000`.

For the current ChatGPT/Codex subscription route, the proposed persistent `~/.pi/agent/models.json` is:

```json
{
  "providers": {
    "openai-codex": {
      "modelOverrides": {
        "gpt-5.6-sol": { "contextWindow": 872000 },
        "gpt-5.6-terra": { "contextWindow": 872000 },
        "gpt-5.6-luna": { "contextWindow": 872000 }
      }
    }
  }
}
```

For direct OpenAI API-key usage (`OPENAI_API_KEY`, provider `openai`) rather than ChatGPT/Codex OAuth, pi's documented value is `1050000`:

```json
{
  "providers": {
    "openai": {
      "modelOverrides": {
        "gpt-5.6-luna": { "contextWindow": 1050000 }
      }
    }
  }
}
```

Do not put the direct-OpenAI override under `openai` when the selected pi provider is `openai-codex`; provider names are part of the override key. Do not edit `models-store.json`; it is a generated/cache catalog and may be refreshed.

This repository's pi auto-compact extension reads the selected model's `contextWindow` and currently has `autoCompactPercent=80` in the generated `~/.pi/agent/auto-compact-settings.json`. After the override, `/auto-compact status` should therefore show an 872K context window and an approximately 698K local trigger. That is pi's local compaction policy, not proof that the backend accepted a request of that size.

## Recommendation

1. Keep `~/.codex/config.toml` unchanged for pi; Codex and pi have separate configuration layers.
2. Add the `openai-codex` `modelOverrides` above declaratively to this dotfiles module, then rebuild Home Manager.
3. Start a fresh pi session or reload/select the model so `models.json` is read.
4. Verify `/auto-compact status` and the context indicator.
5. Treat 872K as the safe catalog-aligned value. Use 900K only if you deliberately accept a possible overflow and faster subscription usage burn.
6. If the goal is the full published 1.05M capability, use the direct OpenAI API provider and its separate billing/authentication path; the ChatGPT/Codex subscription route is currently cataloged differently.

A live long-context request is still required to validate the backend/account entitlement. A pi status display validates only pi's local metadata and compaction behavior.
