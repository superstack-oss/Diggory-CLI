---
name: diggory
description: "Drive the installed Diggory CLI (`digg`) safely, including machine-readable status, analysis, history, and dry-run surfaces. Use before running `digg` on a user's Mac. Not for editing or reviewing Diggory source code."
---

# Using Diggory from an agent

Diggory (`digg`) cleans, uninstalls, analyzes, optimizes, and monitors a Mac. It is
a real deletion tool operating on someone's live machine, so the way an agent
uses it differs from the way a human does: never guess, never let a TUI decide,
and never let a destructive command run without the user having seen the list.

## The rules

1. **Preview before you delete. Always.** Every destructive command takes
   `--dry-run`. Run it, read the result, show the user what would go, and only
   then offer the real run. An agent that runs `digg clean` before `digg clean
   --dry-run` has skipped the only step the user can veto.
2. **The user runs the destructive command, not you**, unless they explicitly
   asked you to do it in the current turn. "Clean my Mac" is such an ask;
   "why is my disk full" is not.
3. **Never parse a TUI frame.** Interactive `digg analyze` and terminal-attached
   `digg status` are full-screen Go programs whose output is drawn, not printed.
   Use `digg analyze --json`, `digg status --json`, or `digg status --watch` instead.
4. **Never invent flags.** The command surface is small and listed here; if
   something is not on this page, run `digg <command> --help` and read it, do not
   assume a `--yes` or `--force` exists.
5. **Protection is a whitelist, not an argument.** If the user wants a cache
   kept, the answer is `digg clean --whitelist`, not a hand-rolled `find`. Never
   work around Diggory's safety layer with raw `rm`.

## What answers which question

| The user asks | Command |
|---|---|
| "What is eating my disk?" | `digg analyze --json` (whole disk) or `digg analyze <path> --json` |
| "Free up space" | `digg clean --dry-run`, review, then `digg clean` |
| "Remove this app completely" | `digg uninstall --dry-run` then `digg uninstall` |
| "My Mac feels slow" / caches look broken | `digg optimize --dry-run` then `digg optimize` |
| "Clean up my old projects" | `digg purge --dry-run` then `digg purge` |
| "Get rid of downloaded installers" | `digg installer --dry-run` then `digg installer` |
| "What did Diggory delete?" | `digg history --json --limit 20` |
| One CPU / memory / disk / network snapshot | `digg status --json` |
| A short time series for diagnosis | `digg status --watch --interval 1s` (NDJSON; stop after enough samples) |

## Machine-readable surfaces

These four surfaces are the agent-facing API. Everything else is for humans.

**Disk usage.** `digg analyze --json` prints one JSON object: `path`, `overview`,
and `entries[]` of `{name, path, size, is_dir, insight}`. `size` is bytes.
`insight: true` marks an entry Diggory considers noteworthy (a large iOS backup, a
runaway cache). Pass a path to scope it: `digg analyze ~/Library --json`.

**Cleanup history.** `digg history --json [--limit N]` (N is 1-200) prints
`logs` (paths of the operations and deletions logs) plus `sessions[]` with
`command`, `started_at`, `items`, `size`, and an `actions` breakdown of
removed / trashed / skipped / failed. This is how you answer "did Diggory delete
my file" without guessing: the deletions log has the paths.

**The dry-run path list.** `digg clean --dry-run` prints a summary to the
terminal and writes every candidate path to `~/.config/diggory/clean-list.txt`.
Read that file, not the terminal output, when you need to reason about or show
the user exactly what a real run would remove. This list is clean-only: `digg
purge --dry-run` and `digg installer --dry-run` print their candidates to the
terminal and write no file.

**System status.** `digg status --json` prints one metrics snapshot. It also
switches to JSON automatically when stdout is not a TTY, but pass `--json`
explicitly in scripts so intent stays obvious. `digg status --watch --interval
1s` emits one complete JSON object per line from a warm collector. Bound the
watch duration or sample count and terminate it after collecting the evidence
the user asked for; do not leave an unbounded monitor running in the background.

## Command notes worth knowing

- `digg clean` also sweeps leftovers from apps the user already deleted. It does
  not touch installed apps; that is `digg uninstall`.
- `digg clean --external <path>` cleans macOS metadata off an external volume.
- `digg purge` removes rebuildable project artifacts: local build output
  (`target/`, `build/`, `dist/`, `.next/`) and dependency directories that need
  a network to restore (`node_modules/`, `Pods/`, `venv/`, `vendor/`). A purge
  is therefore not always recoverable offline, so say which kind the candidates
  are before running it. `digg purge --paths` configures which directories are
  scanned; `--include-empty` shows zero-size candidates.
- `digg optimize` refreshes caches and system services. It is the one destructive
  command whose effects are not "files disappear", so say what it will do
  before running it.
- `digg update` self-updates; `digg update --nightly` installs unreleased `main`.
  Do not run either on a user's behalf without being asked.
- `--debug` on any command prints the detailed operation log. Reach for it when
  a command silently did nothing; do not leave it on in normal use.

## When something goes wrong

**`digg clean` deletions are permanent by default.** Cache cleanup removes files
rather than moving them to the Trash, so there is usually nothing to restore.
That is exactly why rule 1 exists: the dry-run is the undo. `digg uninstall` is
the exception: it routes the app and its leftovers through the Trash, so an
uninstalled app is recoverable until the Trash is emptied.

What you do have is a record. `digg history --json` names the deletions log, and
every deletion is one tab-separated line in it: timestamp, mode, size, status,
path. So when a user asks "did Diggory take my file", read the log and answer with
the actual line instead of guessing. Then add the path to the whitelist (`digg
clean --whitelist`) so the next run leaves it alone.
