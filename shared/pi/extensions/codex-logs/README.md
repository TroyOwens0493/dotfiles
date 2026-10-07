# Codex-compatible Pi logs

This extension mirrors Pi sessions into Codex's rollout JSONL layout so local tools that scan `~/.codex/sessions` can include Pi usage.

## Live export

Pi auto-loads `index.ts` as a global extension. On session start and after each finalized message, it rewrites a deterministic shadow file under:

```text
~/.codex/sessions/YYYY/MM/DD/rollout-<timestamp>-<pi-session-id>.jsonl
```

Use `/codex-log` to force a rewrite and display the current output path.

The extension emits Codex-compatible session metadata, response items, tool calls/results, reasoning summaries, and cumulative `token_count` events. Codex subscription rate-limit windows are emitted as `null` because Pi's extension API does not expose the rate-limit payload from the provider stream.

The exporter intentionally does not add Pi sessions to `~/.codex/session_index.jsonl`, which keeps them out of Codex's normal session picker while still making them available to tools that scan rollout logs.

## Retroactive import

Preview all existing Pi sessions:

```sh
cd ~/.pi/agent/extensions/codex-logs
npm run import -- --dry-run
```

Export them:

```sh
npm run import
```

Options:

```text
--input <path>   Pi sessions root or one JSONL file
--output <path>  Codex sessions root
--dry-run        Print destinations without writing
```

The import is idempotent: each Pi session maps to one deterministic output path, and rerunning it replaces that generated file with a fresh export.
