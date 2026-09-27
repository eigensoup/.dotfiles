# ==============================================================================

# Powerlevel10k instant prompt

# ==============================================================================

# Keep this near the top of ~/.zshrc.

# Anything that may request user input must appear before this block.

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then

  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"

fi

# ==============================================================================

# Homebrew

# ==============================================================================

if [[ -x "/opt/homebrew/bin/brew" ]]; then

  eval "$(/opt/homebrew/bin/brew shellenv)"

fi

# ==============================================================================

# PATH

# ==============================================================================

typeset -U path PATH

path=(

  "$HOME/.local/bin"

  "$HOME/.cargo/bin"

  "$HOME/.bun/bin"

  "$HOME/.opencode/bin"

  "$HOME/.omnara/bin"

  "$HOME/.antigravity/antigravity/bin"

  "$HOME/.antigravity-ide/antigravity-ide/bin"

  "/opt/homebrew/opt/python@3.12/bin"

  "/opt/homebrew/bin"

  $path

)

export PATH

# ==============================================================================

# Core environment

# ==============================================================================

export ZSH="$HOME/.oh-my-zsh"

export BUN_INSTALL="$HOME/.bun"

export NVM_DIR="$HOME/.nvm"

export OLLAMA_CONTEXT_LENGTH="32768"

export LANG="en_US.UTF-8"

export LC_ALL="en_US.UTF-8"

export EDITOR="nvim"

export VISUAL="$EDITOR"

# ==============================================================================

# Secrets

# ==============================================================================

if [[ -r "$HOME/.dotfiles/zsh/secrets.zsh" ]]; then

  source "$HOME/.dotfiles/zsh/secrets.zsh"

elif [[ -r "$HOME/workstation/zsh/secrets.zsh" ]]; then

  source "$HOME/workstation/zsh/secrets.zsh"

elif [[ -r "$HOME/.zsh/secrets.zsh" ]]; then

  source "$HOME/.zsh/secrets.zsh"

elif [[ -r "$HOME/zsh/secrets.zsh" ]]; then

  source "$HOME/zsh/secrets.zsh"

elif [[ -r "$HOME/.config/zsh/secrets.zsh" ]]; then

  source "$HOME/.config/zsh/secrets.zsh"

fi

# ==============================================================================

# Anthropic key from macOS Keychain

# ==============================================================================

if [[ -z "${ANTHROPIC_API_KEY:-}" ]] && command -v security >/dev/null 2>&1; then

  ANTHROPIC_API_KEY="$(
    security find-generic-password \
      -a "$USER" \
      -s "anthropic_barnabus_native" \
      -w 2>/dev/null
  )" || true

  if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then

    export ANTHROPIC_API_KEY

  else

    unset ANTHROPIC_API_KEY

  fi

fi

# ==============================================================================

# Oh My Zsh

# ==============================================================================

plugins=(

  git

  zsh-autosuggestions

  zsh-syntax-highlighting

)

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then

  source "$ZSH/oh-my-zsh.sh"

else

  print -u2 "Warning: Oh My Zsh was not found at $ZSH"

fi

# ==============================================================================

# Powerlevel10k

# ==============================================================================

P10K_THEME="/opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme"

if [[ -r "$P10K_THEME" ]]; then

  source "$P10K_THEME"

else

  print -u2 "Warning: Powerlevel10k was not found at $P10K_THEME"

fi

if [[ -r "$HOME/.p10k.zsh" ]]; then

  source "$HOME/.p10k.zsh"

fi

unset P10K_THEME

# ==============================================================================

# Tool integrations

# ==============================================================================

if command -v direnv >/dev/null 2>&1; then

  eval "$(direnv hook zsh)"

fi

GCLOUD_COMPLETION="/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc"

if [[ -r "$GCLOUD_COMPLETION" ]]; then

  source "$GCLOUD_COMPLETION"

fi

unset GCLOUD_COMPLETION

if [[ -r "$HOME/.cargo/env" ]]; then

  source "$HOME/.cargo/env"

fi

if [[ -r "$HOME/.local/bin/env" ]]; then

  source "$HOME/.local/bin/env"

fi

if [[ -r "$NVM_DIR/nvm.sh" ]]; then

  source "$NVM_DIR/nvm.sh"

fi

if [[ -r "$NVM_DIR/bash_completion" ]]; then

  source "$NVM_DIR/bash_completion"

fi

if [[ -r "$BUN_INSTALL/_bun" ]]; then

  source "$BUN_INSTALL/_bun"

fi

# ==============================================================================

# LLM proxy configuration

# ==============================================================================

export LLM_PROXY_MODE="${LLM_PROXY_MODE:-direct}"

export ENABLE_TOOL_SEARCH="${ENABLE_TOOL_SEARCH:-true}"

configure_llm_proxy() {

  case "$LLM_PROXY_MODE" in

    headroom)

      export HEADROOM_PORT="${HEADROOM_PORT:-8787}"

      export HEADROOM_HOST="${HEADROOM_HOST:-127.0.0.1}"

      export HEADROOM_MODE="${HEADROOM_MODE:-token}"

      export HEADROOM_BACKEND="${HEADROOM_BACKEND:-anthropic}"

      export HEADROOM_TELEMETRY="${HEADROOM_TELEMETRY:-on}"

      export ANTHROPIC_BASE_URL="http://${HEADROOM_HOST}:${HEADROOM_PORT}"

      export OPENAI_BASE_URL="http://${HEADROOM_HOST}:${HEADROOM_PORT}/v1"

      export OPENAI_API_BASE="$OPENAI_BASE_URL"

      unset ANTIGRAVITY_API_BASE_URL

      ;;

    direct)

      unset ANTHROPIC_BASE_URL

      unset OPENAI_BASE_URL

      unset OPENAI_API_BASE

      unset ANTIGRAVITY_API_BASE_URL

      unset HEADROOM_PORT

      unset HEADROOM_HOST

      unset HEADROOM_MODE

      unset HEADROOM_BACKEND

      unset HEADROOM_TELEMETRY

      ;;

    *)

      print -u2 "Warning: unknown LLM_PROXY_MODE '$LLM_PROXY_MODE'"

      print -u2 "Expected: headroom or direct"

      return 1

      ;;

  esac

}

configure_llm_proxy

# ==============================================================================

# Agent wrappers

# ==============================================================================

# codex uses the ChatGPT login: strip OpenAI API credentials and base URLs.
# `env` execs the binary directly, so it can't recurse into this function.
codex() {
  env \
    -u OPENAI_API_KEY \
    -u OPENAI_API_TOKEN \
    -u OPENAI_BASE_URL \
    -u OPENAI_API_BASE \
    codex "$@"
}

claude-rc() {
  (
    # Disable Headroom & proxy environment for this invocation
    unset ANTHROPIC_BASE_URL
    unset ANTHROPIC_API_KEY
    unset ANTHROPIC_AUTH_TOKEN

    # Launch Claude Remote Control
    exec claude --remote-control "$@"
  )
}


# ==============================================================================

# History

# ==============================================================================

HISTFILE="$HOME/.zsh_history"

HISTSIZE=100000

SAVEHIST=100000

setopt APPEND_HISTORY

setopt EXTENDED_HISTORY

setopt HIST_EXPIRE_DUPS_FIRST

setopt HIST_FIND_NO_DUPS

setopt HIST_IGNORE_ALL_DUPS

setopt HIST_IGNORE_SPACE

setopt HIST_REDUCE_BLANKS

setopt INC_APPEND_HISTORY

setopt SHARE_HISTORY

# ==============================================================================

# Shell behavior

# ==============================================================================

setopt INTERACTIVE_COMMENTS

setopt AUTO_CD

setopt AUTO_PUSHD

setopt PUSHD_IGNORE_DUPS

setopt PUSHD_SILENT

unsetopt BEEP

# ==============================================================================

# Completion

# ==============================================================================

zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[-_]=* r:|=*'

zstyle ':completion:*' menu select

zstyle ':completion:*' group-name ''

zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS:-}"

# ==============================================================================

# Optional modern CLI integrations

# ==============================================================================

if command -v zoxide >/dev/null 2>&1; then

  eval "$(zoxide init zsh)"

fi

if command -v fzf >/dev/null 2>&1; then

  if [[ -r "$HOME/.fzf.zsh" ]]; then

    source "$HOME/.fzf.zsh"

  elif [[ -r "/opt/homebrew/opt/fzf/shell/completion.zsh" ]]; then

    source "/opt/homebrew/opt/fzf/shell/completion.zsh"

    if [[ -r "/opt/homebrew/opt/fzf/shell/key-bindings.zsh" ]]; then

      source "/opt/homebrew/opt/fzf/shell/key-bindings.zsh"

    fi

  fi

fi

# ==============================================================================

# Aliases

# ==============================================================================

alias reload='source "$HOME/.zshrc"'

alias zshconfig='${EDITOR:-nvim} "$HOME/.zshrc"'

alias p10kconfig='${EDITOR:-nvim} "$HOME/.p10k.zsh"'

alias ..='cd ..'

alias ...='cd ../..'

alias ....='cd ../../..'

alias grep='grep --color=auto'

if command -v eza >/dev/null 2>&1; then

  alias ls='eza --icons=auto'

  alias l='eza --long --icons=auto'

  alias la='eza --all --icons=auto'

  alias ll='eza --long --all --git --icons=auto'

  alias tree='eza --tree --icons=auto'

else

  alias la='ls -A'

  alias ll='ls -lah'

fi

if command -v bat >/dev/null 2>&1; then

  alias cat='bat --paging=never'

fi

if command -v git >/dev/null 2>&1; then

  alias gs='git status'

  alias ga='git add'

  alias gc='git commit'

  alias gp='git push'

  alias gl='git pull'

  alias gd='git diff'

  alias gco='git checkout'

  alias gb='git branch'

fi

# Added by jcode installer
export PATH="/Users/eigensoup/.local/bin:$PATH"

# cli-anything-zotero
export PATH="/Users/eigensoup/Library/Python/3.14/bin:$PATH"
