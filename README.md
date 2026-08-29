<div align="center">
  <h1>Diggory</h1>
  <p><em>🐹 Clean, uninstall, analyze, optimize, and monitor your Mac from the terminal.</em></p>
</div>

<p align="center">
  <a href="https://github.com/superstack-oss/Diggory-CLI/stargazers"><img src="https://img.shields.io/github/stars/superstack-oss/Diggory-CLI?style=flat-square" alt="Stars"></a>
  <a href="https://github.com/superstack-oss/Diggory-CLI/releases"><img src="https://img.shields.io/github/v/tag/superstack-oss/Diggory-CLI?label=version&style=flat-square" alt="Version"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL_v3-blue.svg?style=flat-square" alt="License"></a>
  <a href="https://github.com/superstack-oss/Diggory-CLI/commits"><img src="https://img.shields.io/github/commit-activity/m/superstack-oss/Diggory-CLI?style=flat-square" alt="Commits"></a>
</p>

## Features

- **All-in-one toolkit**: Combines CleanMyMac, AppCleaner, DaisyDisk, and iStat Menus in a **single binary**
- **Deep cleaning**: Removes caches, logs, leftovers, and orphaned app data to **reclaim gigabytes of space**
- **Smart uninstaller**: Removes apps plus launch agents, preferences, and **hidden remnants**
- **Disk insights**: Visualizes usage, finds large files, **rebuilds caches**, and refreshes system services
- **Live monitoring**: Shows real-time CPU, GPU, memory, disk, and network stats

## Quick Start

**Install via Homebrew tap**

```bash
brew install superstack-oss/tap/diggory
```

This installs the `diggory` command and the `digg` alias. Homebrew Core (`brew install diggory` with no tap) is not available yet.

**Or via script**

```bash
# Optional args: -s latest for main branch code, -s 1.0.0 for a specific version
curl -fsSL https://raw.githubusercontent.com/superstack-oss/Diggory-CLI/main/install.sh | bash
```

> Note: Diggory is built for macOS.

**Run**

```bash
digg                           # Interactive menu
digg clean                     # Deep cleanup + already-uninstalled app leftovers
digg uninstall                 # Remove installed apps + their leftovers
digg optimize                  # Refresh caches & services
digg analyze                   # Visual disk explorer (or 'digg analyse')
digg status                    # Live system health dashboard
digg purge                     # Clean project build artifacts
digg installer                 # Find and remove installer files

digg touchid                   # Configure Touch ID for sudo
digg completion                # Set up shell tab completion
digg update                    # Update Diggory
digg update --nightly          # Update to latest unreleased main build, script install only
digg remove                    # Remove Diggory from system
digg --help                    # Show help
digg --version                 # Show installed version
```

**Preview safely**

```bash
digg clean --dry-run
digg uninstall --dry-run
digg history
digg history --json
digg purge --dry-run

# Also works with: optimize, installer, remove, completion, touchid enable
digg clean --dry-run --debug   # Preview + detailed logs
digg optimize --whitelist      # Manage protected optimization rules
digg clean --whitelist         # Manage protected caches
digg purge --paths             # Configure project scan directories
digg analyze /Volumes          # Analyze external drives only
digg analyze /private/tmp      # Review user-owned temporary directories
```

Selections made with `digg clean --whitelist` persist in `~/.config/diggory/whitelist`.

## Security & Safety Design

Diggory is a local system maintenance tool, and some commands can perform destructive local operations.

Diggory uses safety-first defaults: path validation, protected-directory rules, conservative cleanup boundaries, and explicit confirmation for higher-risk actions. When risk or uncertainty is high, Diggory skips, refuses, or requires stronger confirmation rather than broadening deletion scope.

`digg analyze` is safer for ad hoc cleanup because it moves files to Trash through Finder instead of deleting them directly.

Review [SECURITY.md](SECURITY.md) and [SECURITY_AUDIT.md](SECURITY_AUDIT.md) for reporting guidance, safety boundaries, and current limitations.

## Tips

- Video tutorial: Watch the [Diggory tutorial video](https://www.youtube.com/watch?v=UEe9-w4CcQ0), thanks to PAPAYA 電腦教室.
- Safety and logs: `clean`, `uninstall`, `purge`, `installer`, and `remove` are destructive. Review with `--dry-run` first, and add `--debug` when needed. File operations are logged to `~/Library/Logs/diggory/operations.log` and can be reviewed with `digg history`. Disable with `MO_NO_OPLOG=1`. Review [SECURITY.md](SECURITY.md) and [SECURITY_AUDIT.md](SECURITY_AUDIT.md).
- App leftovers: use `digg clean` when the app is already uninstalled, and `digg uninstall` when the app is still installed.
- Navigation: Diggory supports arrow keys and Vim bindings `h/j/k/l`.

## Features in Detail

### Deep System Cleanup

```bash
$ digg clean

Scanning cache directories...

  ✓ User app cache                                           45.2GB
  ✓ Browser cache (Chrome, Safari, Firefox)                  10.5GB
  ✓ Developer tools (Xcode, Node.js, npm)                    23.3GB
  ✓ System logs and temp files                                3.8GB
  ✓ App-specific cache (Spotify, Dropbox, Slack)              8.4GB
  ✓ Trash                                                    12.3GB

====================================================================
Space freed: 95.5GB | Free space now: 223.5GB
====================================================================
```

Note: In `digg clean` -> Developer tools, Diggory removes unused CoreSimulator `Volumes/Cryptex` entries and skips `IN_USE` items.

### Smart App Uninstaller

```bash
$ digg uninstall

Select Apps to Remove
═══════════════════════════
▶ ☑ Photoshop 2024            (4.2G) | Old
  ☐ IntelliJ IDEA             (2.8G) | Recent
  ☐ Premiere Pro              (3.4G) | Recent

Uninstalling: Photoshop 2024

  ✓ Removed application
  ✓ Cleaned 52 related files across 12 locations
    - Application Support, Caches, Preferences
    - Logs, WebKit storage, Cookies
    - Extensions, Plugins, Launch daemons

====================================================================
Space freed: 12.8GB
====================================================================
```

### System Optimization

```bash
$ digg optimize

System: 5/32 GB RAM | 333/460 GB Disk (72%) | Uptime 6d

  ✓ Inspect and repair supported system maintenance items
  ✓ Refresh eligible Finder, network, and database state
  ✓ Skip tasks that are unnecessary, unsafe now, or unavailable

====================================================================
Optimization Complete
====================================================================
Applied 8 optimizations
9 unchanged | 4 skipped | 2 unavailable
Optimization pass complete
```

Use `digg optimize --whitelist` to exclude specific optimizations. Path patterns work too, so you can keep a long-lived mounted disk image around (for example `/Volumes/mail`) without it showing up as a detach candidate.

Optimize results depend on the Mac's current state and available system tools, so the counts above are illustrative rather than fixed.

### Disk Space Analyzer

> Note: By default, Diggory skips external drives under `/Volumes` for faster startup. To inspect them, run `digg analyze /Volumes` or a specific mount path.

Developer tools may leave large temporary directories under `/private/tmp`. Review user-owned entries with `digg analyze /private/tmp`; selected entries move to Trash only after confirmation. Diggory does not automatically delete third-party temporary directories because build markers and age alone cannot prove that a checkout or worktree is disposable.

```bash
$ digg analyze

Analyze Disk  (302.1GB free)
Select a location to explore:

 ▶  1. ████████████████████████  47.9%  |  Home                       75.4GB
    2. ███████████               22.0%  |  User Library               34.6GB
    3. ███████                   14.2%  |  Applications               22.4GB
    4. █████                     10.7%  |  System Library             16.9GB
    5. ███                        5.2%  |  Old Downloads (90d+)       8.2GB  >3mo

↑↓→ | Enter | R Refresh | O Open | P Preview | F File | Esc/Q Quit
```

### Live System Status

Real-time dashboard with health score, hardware info, and performance metrics.

```bash
$ digg status

Diggory Status  Health ● 92  MacBook Pro · M4 Pro · 32GB · macOS 14.5

⚙ CPU                                    ▦ Memory
Total   ████████████░░░░░░░  45.2%       Used    ███████████░░░░░░░  58.4%
Load    0.82 / 1.05 / 1.23 (8 cores)     Total   14.2 / 24.0 GB
Core 1  ███████████████░░░░  78.3%       Free    ████████░░░░░░░░░░  41.6%
Core 2  ████████████░░░░░░░  62.1%       Avail   9.8 GB

▤ Disk                                   ⚡ Power
Used    █████████████░░░░░░  67.2%       Level   ██████████████████  100%
Free    156.3 GB                         Status  Charged
Read    ▮▯▯▯▯  2.1 MB/s                  Health  Normal · 423 cycles
Write   ▮▮▮▯▯  18.3 MB/s                 Temp    58°C · 1200 RPM

⇅ Network                                ▶ Processes
Down    ▁▁█▂▁▁▁▁▁▁▁▁▇▆▅▂  0.54 MB/s      Code       ▮▮▮▮▯  42.1%
Up      ▄▄▄▃▃▃▄▆▆▇█▁▁▁▁▁  0.02 MB/s      Chrome     ▮▮▮▯▯  28.3%
Proxy   HTTP · 192.168.1.100             Terminal   ▮▯▯▯▯  12.5%
```

Health score is based on CPU, memory, disk, temperature, and I/O load, with color-coded ranges.

Shortcuts: In `digg status`, press `k` to toggle the cat, `c` to cycle how many CPU cores the card lists (2, 4, 8, all), and `q` to quit. Both preferences are saved.

When enabled, `digg status` shows a read-only alert banner for processes that stay above the configured CPU threshold for a sustained window. Use `--proc-cpu-threshold`, `--proc-cpu-window`, or `--proc-cpu-alerts=false` to tune or disable it.

#### Machine-Readable Output

Both `digg analyze` and `digg status` support a `--json` flag for scripting and automation.

`digg status` also auto-detects when its output is piped (not a terminal) and switches to JSON automatically.

```bash
# Disk analysis as JSON
$ digg analyze --json ~/Documents
{
  "path": "/Users/you/Documents",
  "overview": false,
  "entries": [
    { "name": "Library", "path": "...", "size": 80939438080, "is_dir": true },
    ...
  ],
  "large_files": [
    { "name": "backup.zip", "path": "...", "size": 8796093022 }
  ],
  "total_size": 168393441280,
  "total_files": 42187
}

# System status as JSON
$ digg status --json
{
  "host": "MacBook-Pro",
  "health_score": 92,
  "cpu": { "usage": 45.2, "logical_cpu": 8, ... },
  "memory": { "total": 25769803776, "used": 15049334784, "used_percent": 58.4 },
  "disks": [ ... ],
  "uptime": "3d 12h 45m",
  ...
}

# Auto-detected JSON when piped
$ digg status | jq '.health_score'
92
```

### Project Artifact Purge

Clean old build artifacts such as `node_modules`, `target`, `.build`, `build`, and `dist` to free up disk space.

```bash
digg purge

Select Categories to Clean - 18.5GB (8 selected)

➤ ● my-react-app       3.2GB | node_modules
  ● old-project        2.8GB | node_modules
  ● rust-app           4.1GB | target
  ● next-blog          1.9GB | node_modules
  ○ current-work       856MB | node_modules  | Recent
  ● django-api         2.3GB | venv
  ● vue-dashboard      1.7GB | node_modules
  ● backend-service    2.5GB | node_modules
```

> Note: We recommend installing `fd` on macOS.
> `brew install fd`

> Safety: This permanently deletes selected artifacts. Review carefully before confirming. Projects newer than 7 days are marked and unselected by default.

<details>
<summary><strong>Custom Scan Paths</strong></summary>

Run `digg purge --paths` to configure scan directories, or edit `~/.config/diggory/purge_paths` directly:

```shell
~/Documents/MyProjects
~/Work/ClientA
~/Work/ClientB
```

When custom paths are configured, Diggory scans only those directories. Otherwise, it uses defaults like `~/Projects`, `~/GitHub`, and `~/dev`.

</details>

### Installer Cleanup

Find and remove large installer files across Downloads, Desktop, Homebrew caches, iCloud, and Mail. Each file is labeled by source.

```bash
digg installer

Select Installers to Remove - 3.8GB (5 selected)

➤ ● Photoshop_2024.dmg     1.2GB | Downloads
  ● IntelliJ_IDEA.dmg       850.6MB | Downloads
  ● Illustrator_Setup.pkg   920.4MB | Downloads
  ● PyCharm_Pro.dmg         640.5MB | Homebrew
  ● Acrobat_Reader.dmg      220.4MB | Downloads
  ○ AppCode_Legacy.zip      410.6MB | Downloads
```

## Quick Launchers

Launch Diggory commands from Raycast or Alfred:

```bash
curl -fsSL https://raw.githubusercontent.com/superstack-oss/Diggory-CLI/main/scripts/setup-quick-launchers.sh | bash
```

Adds 5 commands: `Diggory Clean`, `Diggory Uninstall`, `Diggory Optimize`, `Diggory Analyze`, `Diggory Status`.

### Raycast Setup

After running the script, complete these steps in Raycast:

1. Open Raycast Settings (⌘ + ,)
2. Go to **Extensions** → **Script Commands**
3. Click **"Add Script Directory"** (or **"+"**)
4. Add path: `~/Library/Application Support/Raycast/script-commands`
5. Search in Raycast for: **"Reload Script Directories"** and run it
6. Done! Search for `Diggory Clean` or `clean`, `Diggory Optimize`, or `Diggory Status` to use the commands

> **Note**: The script creates the commands, but Raycast still requires a one-time manual script directory setup.

### Terminal Detection

Diggory auto-detects your terminal app. iTerm2 has known compatibility issues. Alacritty, kitty, WezTerm, Ghostty, and Warp are good options. To override, set `MO_LAUNCHER_APP=<name>`.

## Support

If Diggory helped you, give the [repo](https://github.com/superstack-oss/Diggory-CLI) a star or open an issue or PR.

## License

Diggory is open source under GPL-3.0, see [LICENSE](LICENSE). A version you modify and share stays open under the same license. If you fork Diggory into your own product, please give it a different name and credit this project as the source.
