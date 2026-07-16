#
# Executes commands at the start of an interactive session.
#

# ---------------------------------------------------------------------------
# History
# ---------------------------------------------------------------------------
HISTFILE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/history"
HISTSIZE=10000
SAVEHIST=10000
[[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}"

setopt EXTENDED_HISTORY        # record command start time
setopt SHARE_HISTORY           # share history between sessions
setopt INC_APPEND_HISTORY      # append as commands are entered
setopt HIST_IGNORE_ALL_DUPS    # drop older duplicates
setopt HIST_IGNORE_SPACE       # skip commands starting with a space
setopt HIST_REDUCE_BLANKS      # trim superfluous blanks
setopt HIST_VERIFY             # don't run history expansions immediately

# ---------------------------------------------------------------------------
# Directory navigation
# ---------------------------------------------------------------------------
setopt AUTO_CD                 # `cd` into a dir by typing its name
setopt AUTO_PUSHD              # maintain a dir stack on cd
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# ---------------------------------------------------------------------------
# Completion
# ---------------------------------------------------------------------------
autoload -Uz compinit
_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
[[ -d "${_zcompdump:h}" ]] || mkdir -p "${_zcompdump:h}"
compinit -d "$_zcompdump"

zstyle ':completion:*' menu no                              # fzf-tab drives selection instead
# case-insensitive, then word-boundary, then substring-anywhere matching
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' rehash true
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# ---------------------------------------------------------------------------
# Keybindings (emacs)
# ---------------------------------------------------------------------------
bindkey -e
bindkey '^[[H'    beginning-of-line
bindkey '^[[F'    end-of-line
bindkey '^[[3~'   delete-char
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[^['    kill-whole-line  # Esc-Esc clears the whole line (Ctrl-U also works)

# Color ls
export CLICOLOR=1
export LSCOLORS=ExFxCxDxBxegedabagacad

# setup brew if available (macOS and Linux install locations)
for _brew in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  if [[ -x $_brew ]]; then
    eval "$($_brew shellenv)"
    break
  fi
done
unset _brew

# setup pyenv if available
if command -v pyenv &>/dev/null; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi

# setup rbenv if available
if command -v rbenv &>/dev/null; then
  eval "$(rbenv init -)"
fi

# setup HashiCorp VagrantCloud (used to be Atlas)
if [[ -s "${HOME}/.vagrantcloud" ]]; then
  export ATLAS_TOKEN=$(cat $HOME/.vagrantcloud)
fi

# setup kubectl autocompletion
if [ $commands[kubectl] ]; then
  source <(kubectl completion zsh);
fi

# setup gcloud autocompletion
if command -v gcloud &>/dev/null; then
  source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
  source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
fi

# setup ngrok autocompletion
if command -v ngrok &>/dev/null; then
  eval "$(ngrok completion)"
fi

# Make "kubecolor" borrow the same completion logic as "kubectl"
if command -v kubecolor &>/dev/null; then
  compdef kubecolor=kubectl
fi

# Aliases for non-native tools
declare -A extAliases
extAliases=(
  [cat]="bat"
  [cdiff]="colordiff -u"
  [kc]="kubecolor"
  [kctx]="kubectx"
  [kcns]="kubens"
  [kcq]="cyphernetes query"
  [ll]="eza -aghl --color-scale --git --group-directories-first"
  [pbc]="pbcopy"
  [pbp]="pbpaste"
  [rg]="rg --hidden -g '!.git' -g '!.terraform'"
  [tf]="tofu"
  [tg]="terragrunt"
  [tfdocs]="terraform-docs"
  [tree]="tree -I vendor -I .terraform -I .terragrunt-cache -I .git -a --dirsfirst"
  [urldecode]='python3 -c "import sys, urllib.parse as ul; print(ul.unquote_plus(sys.argv[1]))"'
  [urlencode]='python3 -c "import sys, urllib.parse as ul; print (ul.quote_plus(sys.argv[1]))"'
  [vi]="nvim"
)

for key value in ${(kv)extAliases}; do
  cmd=${value%% *}

  if command -v $cmd &>/dev/null; then
    alias $key=$value
  fi
done

# Wayland stand-ins for the macOS clipboard aliases above
if ! command -v pbcopy &>/dev/null && command -v wl-copy &>/dev/null; then
  alias pbc="wl-copy" pbp="wl-paste"
fi

# ---------------------------------------------------------------------------
# Plugins (installed via Homebrew)
# ---------------------------------------------------------------------------
if command -v brew &>/dev/null; then
  _brew_prefix="$(brew --prefix)"

  # fzf-driven completion menu (must load after compinit, before the widget-wrapping plugins below)
  source "$_brew_prefix/share/fzf-tab/fzf-tab.zsh" 2>/dev/null
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
  zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept

  # fish-like autosuggestions
  source "$_brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh" 2>/dev/null

  # command syntax highlighting (source before history-substring-search)
  source "$_brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" 2>/dev/null

  # up/down substring search (must be sourced last)
  source "$_brew_prefix/share/zsh-history-substring-search/zsh-history-substring-search.zsh" 2>/dev/null
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down

  unset _brew_prefix
fi

# ---------------------------------------------------------------------------
# fzf key bindings (Ctrl-R history, Ctrl-T files, Alt-C cd) + `**` completion
# ---------------------------------------------------------------------------
if command -v fzf &>/dev/null; then
  source <(fzf --zsh)
fi

# ---------------------------------------------------------------------------
# Prompt
# ---------------------------------------------------------------------------
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# ---------------------------------------------------------------------------
# zoxide — smarter `cd` (frecency jumps); must init at end of file
# ---------------------------------------------------------------------------
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh --cmd cd)"
fi
