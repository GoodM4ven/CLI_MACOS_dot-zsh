# Required for the scripts in this repo.
brew "ffmpeg" # vid-combine, vid-compress, vid-eq-audio, vid-extract-*, vid-pic, vid-trim
brew "aria2"  # download()

# Core CLI tools — useful to both the shell scripts and coding agents.
brew "flock"     # process locking for concurrent event-driven scripts
brew "ripgrep"   # fast repository-wide search
brew "fd"        # fast, agent-friendly file discovery
brew "jq"        # JSON inspection and scripting
brew "yq"        # YAML/XML/CSV inspection and scripting
brew "fzf"       # interactive file/history selection
brew "bat"       # readable source and diff previews
brew "watch"     # lightweight polling while monitoring commands
brew "direnv"    # per-project environment loading
brew "gh"        # GitHub issues, pull requests, and Actions from the CLI
brew "git-lfs"   # large-file support for repositories that require it
brew "git-delta" # readable side-by-side Git diffs
brew "lazygit"   # interactive Git status, history, and staging
brew "shellcheck" # static analysis for the repo's Bash scripts
brew "shfmt"      # consistent shell formatting
brew "tmux"       # persistent terminals for long-running agents and tests

# mise (https://github.com/jdx/mise) is NOT installed via this Brewfile — .zsh_env
# hardcodes ~/.local/bin/mise, which is where the standalone installer puts it
# (`curl https://mise.jdx.dev/install.sh | sh`), not where Homebrew would.

# Window manager / bar / hotkeys — configs live under configs/, symlinked from ~/.config (see README).
tap "asmvik/formulae" # yabai/skhd maintainership moved here from koekeishiya
brew "yabai"           # https://github.com/asmvik/yabai
brew "skhd"            # https://github.com/asmvik/skhd
tap "FelixKratz/formulae"
brew "sketchybar"      # https://github.com/FelixKratz/SketchyBar
cask "font-hack-nerd-font" # sketchybar icons
cask "sf-symbols"          # sketchybar icons
cask "karabiner-elements" # https://github.com/pqrs-org/Karabiner-Elements
cask "hammerspoon" # https://www.hammerspoon.org — sketchybar requirement

# Editor — the `code` function wraps `zed`.
cask "zed" # https://github.com/zed-industries/zed

# Local HTTPS trust — required by lara-stacker's Certify command (`lara`/`permit` aliases).
cask "orbstack" # Docker engine and Compose runtime used by lara-stacker
brew "mkcert" # https://github.com/FiloSottile/mkcert
brew "nss"    # Firefox trust store support for mkcert
brew "imagemagick" # Native library required by mise PHP's imagick/imagick PIE extension

# AI CLIs — configs live under configs/, symlinked from ~/.codex and ~/.claude (see README).
cask "codex"       # https://github.com/openai/codex
cask "claude-code" # https://github.com/anthropics/claude-code
