
<div align="center">بسم الله الرحمن الرحيم</div>

<div align="left">

# Dot-Zsh

An extremely opinionated set of Zsh scripts, app configs, and their setup, that I rely on on [macOS](https://www.apple.com/macos) & [brew](https://brew.sh) for general computing and web development...

The repo is split into:

1. Environment setup
2. Inlined aliases
3. Functioned commands
4. Full script files
5. Linked app configs (`configs/`)


## Setup

1. Keep this repo at a stable path (example):
   ```bash
   ~/Code/Scripts/CLI_MACOS_dot-zsh
   ```
2. Install dependencies via Homebrew (see [Dependencies](#dependencies)):
   ```bash
   brew bundle --file ~/Code/Scripts/CLI_MACOS_dot-zsh/Brewfile
   ```
3. Source all command layers in your `~/.zshrc`:
   ```bash
   DOTZSH="$HOME/Code/Scripts/CLI_MACOS_dot-zsh"
   [ -f "$DOTZSH/.zsh_env" ] && source "$DOTZSH/.zsh_env"
   [ -f "$DOTZSH/.zsh_aliases" ] && source "$DOTZSH/.zsh_aliases"
   [ -f "$DOTZSH/.zsh_functions" ] && source "$DOTZSH/.zsh_functions"
   [ -f "$DOTZSH/.zsh_scripts" ] && source "$DOTZSH/.zsh_scripts"
   unset DOTZSH
   ```

   > [!CAUTION]
   > Watch out for the spacing needed for Github README when you copy!

4. Ensure script files are executable:
   ```bash
   chmod +x ~/Code/Scripts/CLI_MACOS_dot-zsh/scripts/*.sh
   ```
5. Symlink the app configs you want (see [Linked App Configs](#linked-app-configs-configs)). Example (`mise`):
   ```bash
   mv ~/.config/mise ~/Code/Scripts/CLI_MACOS_dot-zsh/configs/mise
   ln -s ~/Code/Scripts/CLI_MACOS_dot-zsh/configs/mise ~/.config/mise
   ```
6. Reload shell:
   ```bash
   source ~/.zshrc
   ```

### Dependencies

- [`mise`](https://github.com/jdx/mise): runtime manager for `node`/`php`/`pnpm`/`python`/etc. Install via `curl https://mise.jdx.dev/install.sh | sh` — not Homebrew, which installs to the wrong path for `.zsh_env`'s activation line.
- [`ffmpeg`](https://ffmpeg.org): powers the `vid-*` scripts.
- `aria2`: powers `download`.
- `python3` + `openpyxl`: for `unicode-csv` (auto-installs `openpyxl`).
- [`zed`](https://github.com/zed-industries/zed): the `code` alias.
- Window manager stack (install docs): [Karabiner-Elements](https://github.com/pqrs-org/Karabiner-Elements), [yabai](https://github.com/asmvik/yabai/wiki/Installing-yabai-(latest-release)), [skhd](https://github.com/asmvik/skhd), [SketchyBar](https://github.com/FelixKratz/SketchyBar), [Hammerspoon](https://www.hammerspoon.org) (SketchyBar requirement) — fonts/icons: Hack Nerd Font, SF Symbols.

Everything above except `mise` is covered by `brew bundle --file Brewfile`.

> [!NOTE]
> `scripts/*.sh` keep `#!/usr/bin/env bash` shebangs and run fine on macOS's stock bash 3.2 — they're separate processes, unaffected by your login shell.


## 0) Environment Setup (`.zsh_env`)

Sourced first — activates tool managers, sets env vars the other layers may need.

- `mise activate zsh`
- `compinit` (loads completions, including OrbStack's, added to `fpath` by `~/.zprofile`)
- `JAVA_HOME` / `PATH` for the Homebrew `openjdk@17` cask
- `ANDROID_HOME` / `PATH` for Android Studio's SDK tools


## 1) Inlined Aliases (`.zsh_aliases`)

Direct aliases, no function wrapper.

### System

- `logout`: logs out via `osascript`.
- `reboot`: confirms, then `sudo reboot`.
- `update`: Homebrew update/upgrade/cleanup, then `softwareupdate -l`.

### Laravel / PHP

- `cda`: `composer dump-autoload`
- `art`: `php artisan`
- `mfs`: `php artisan migrate:fresh --seed`
- `opt`: `php artisan optimize:clear`
- `que`: `php artisan queue:work`
- `pest`: clears terminal then runs `./vendor/bin/pest`
- `green`: clears terminal then runs `composer green`

### TALL-Stack

- `lara`: enters the `lara-stacker` script directory and runs `./lara-stacker.sh`.

### Git

- `oops`: pull current branch with rebase from `origin/<current-branch>`.
- `chest`: stash including untracked files (`git stash push -u`).
- `grit`: merge `origin/dev` using `-X theirs` strategy option.
- `maiv`: hard reset to `origin/main` then force-push with lease.
- `nometa`: disable executable-bit tracking (`core.fileMode false`).

</div>

> [!WARNING]
> `maiv` is destructive (`git reset --hard` + force push). Use only to intentionally discard local divergence.

<div align="left">

### AI

- `codex`: `codex --yolo`.
- `clodex`: `claude --dangerously-skip-permissions`.


## 2) Functioned Commands (`.zsh_functions`)

Real shell functions for argument-aware or multi-step behavior.

### System

- `own [path]`: recursive `chown` to current user/group (defaults to current directory).
- `shutdown [args...]`: confirms, then `sudo shutdown "$@"`.
- `wholecleanup`: empties Trash, cleans Homebrew/npm/pnpm caches, clears Helium browser cache, deletes leftover installers in `~/Downloads`. Prints disk usage before/after.

### Laravel / Testing

- `bench [args...]`: runs Testbench in `local` + `APP_DEBUG=true`.
- `pestbug [slowmo=400] [pest args...]`: headed Playwright debug mode (`HEADLESS=false PWDEBUG=1`) and forwards arguments.

### Git

- `girm <path>`: `git rm -r --cached` for tracked file/dir untracking.
- `oopsie`: pull-rebase current branch, rebase onto `origin/main`, then force-push with lease.

</div>

> [!TIP]
> Use `oops` when your push is rejected because the remote branch moved. Use `oopsie` when your branch is stale against `main` and needs a clean rebase before a PR — it rewrites history, so avoid it on shared branches.

<div align="left">

### Editor / Tools

- `code <path>`: opens path in `zed`.
- `download <url...>`: `aria2c` with aggressive segmented download flags.
- `permit <target>`: runs the external lara-stacker helper at:
  ```bash
  $HOME/Code/Scripts/CLI_LARAVEL_lara-stacker/scripts/helpers/permit.sh
  ```


## 3) Full Script Files (`.zsh_scripts` -> `scripts/*.sh`)

Aliases to standalone scripts, resolved relative to `$HOME/Code/Scripts/CLI_MACOS_dot-zsh/scripts`.

### Arabic

- `aranum`: convert Western digits <-> Arabic-Indic digits.
  - Example: `aranum 1234` -> `١٢٣٤`
- `arastrip`: removes harakat/combining marks and normalizes `ٱ` to `ا`.
  - Example: `arastrip "أَيُّ سَمَاءٍ تُظِلُّنِي، أَوْ أَيُّ أَرْضٍ تُقِلُّنِي، إِنْ أَنَا قُلْتُ فِي كِتابِ اللَّهِ مَا لَا أَعْلَمُ؟"` -> `أي سماء تظلني، أو أي أرض تقلني، إن أنا قلت في كتاب الله ما لا أعلم؟`

### Media (FFmpeg)

- `vid-combine <file1..|list.txt> <output.mp4>`: concatenates clips with timestamp normalization.
- `vid-compress [-1080|-720] [-lq] <input> [output]`: H.265 compression with optional downscale and lower quality mode.
- `vid-eq-audio <input> [output]`: denoise/EQ/loudness-normalized audio track.
- `vid-extract-audio <input> [start] [end] [output.mp3]`: extracts audio (supports flexible timestamps).
- `vid-extract-video <input> [start] [end] [output.mp4]`: extracts video segment with re-encode.
- `vid-pic <file|dir> [output_dir]`: robust thumbnail generator with fallback strategies.
- `vid-trim <input> [start] [end] [output]`: trims with inclusive end handling and safe output flags.

### Utilities

- `unicode-csv <folder|file.csv>`: CSV -> XLSX converter (auto-detects encoding/delimiter, RTL sheet formatting).
- `anyurl <url>`: strips protocol, `www.`, and trailing slash.


## Linked App Configs (`configs/`)

Real config files for a few apps live under `configs/`; their actual system paths are replaced with symlinks pointing back here, so this repo stays the single source of truth. Apps whose config directory only holds harmless local cruft (backups, caches) get the **whole folder** symlinked, with that cruft gitignored. Apps whose directory holds live credentials or session data (`.codex`, `.claude`) get only the one specific file linked, so that data never enters the repo at all.

| App | Install | Symlinked as |
|---|---|---|
| [Karabiner-Elements](https://github.com/pqrs-org/Karabiner-Elements) | in Brewfile | `~/.config/karabiner` -> `configs/karabiner` |
| [yabai](https://github.com/asmvik/yabai) | in Brewfile | `~/.config/yabai` -> `configs/yabai` |
| [skhd](https://github.com/asmvik/skhd) | in Brewfile | `~/.skhdrc` -> `configs/skhd/skhdrc` |
| [SketchyBar](https://github.com/FelixKratz/SketchyBar) | in Brewfile | `~/.config/sketchybar` -> `configs/sketchybar` |
| [Zed](https://github.com/zed-industries/zed) | in Brewfile | `~/.config/zed` -> `configs/zed` |
| [mise](https://github.com/jdx/mise) | `curl https://mise.jdx.dev/install.sh \| sh` (not in Brewfile) | `~/.config/mise` -> `configs/mise` |
| [Codex CLI](https://github.com/openai/codex) | in Brewfile | `~/.codex/config.toml` only |
| [Claude Code](https://github.com/anthropics/claude-code) | in Brewfile | `~/.claude/settings.json` only |
| [Git](https://git-scm.com) | ships with Xcode Command Line Tools | `~/.gitconfig` -> `configs/git/gitconfig` |

To adopt a new machine: install the app, `mv` the real file/dir into the matching `configs/<app>/` path, `ln -s` it back.


## macOS App Stack

The rest of my opinionated macOS setup — mostly `brew install --cask <name>`, config not tracked here.

- [Caffeine](https://intelliscapesolutions.com/apps/caffeine)
- [Macshot](https://github.com/sw33tLie/macshot)
- [AltTab](https://alt-tab.app/)
- [Raycast](https://raycast.com/)
- [Helium](https://helium.computer/)
- [Sloth](https://sveinbjorn.org/sloth)
- [LocalSend](https://localsend.org/)
- [OBS](https://obsproject.com/)
- [HandBrake](https://handbrake.fr/)
- [VLC](https://www.videolan.org/vlc/)
- [Audacity](https://www.audacityteam.org/)
- [Kdenlive](https://kdenlive.org/)
- [GIMP](https://www.gimp.org/)
- [Inkscape](https://inkscape.org/)
- [Proton Mail](https://proton.me/mail)
- [Telegram](https://telegram.org)

### Raycast Extensions

- Color Picker
- Ruler
- Mole
- Image Modification
- Tailwind CSS
- Brew
- QR Code Scanner
- Kill Process
- Change Case
- Lorem Ipsum
- App Cleaner

### Development

- [OrbStack](https://orbstack.dev/)
- [Meld](https://gitlab.com/dehesselle/meld_macos)
- [TablePlus](https://tableplus.com/)
- [Polypane](https://polypane.app/)
- [Firefox](https://www.mozilla.org/firefox/)
- [Google Chrome](https://www.google.com/chrome/)
- [Android Studio](https://developer.android.com/studio/)
- [Xcode](https://apps.apple.com/app/xcode/id497799835)


## Credits

- [mise](https://github.com/jdx/mise)
- [Karabiner-Elements](https://github.com/pqrs-org/Karabiner-Elements)
- [yabai](https://github.com/asmvik/yabai)
- [SketchyBar](https://github.com/FelixKratz/SketchyBar)
- [Raycast](https://raycast.com/)
- [Hammerspoon](https://www.hammerspoon.org)
- [Zed](https://github.com/zed-industries/zed)
- [FFmpeg](https://ffmpeg.org)
- [ChatGPT](https://chatgpt.com)
- [Claude Code](https://claude.com/claude-code)

</div>

<br>
<div align="center">والحمد لله رب العالمين</div>
