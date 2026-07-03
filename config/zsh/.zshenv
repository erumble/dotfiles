#
# Defines environment variables.
#

# Set XDG vars
export XDG_DATA_HOME="${XDG_DATA_HOME:=$HOME/.local/share}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:=$HOME/.config}"
export XDG_STATE_HOME="${XDG_STATE_HOME:=$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:=$HOME/.cache}"
export XDG_DATA_DIRS="${XDG_DATA_DIRS:=/usr/local/share/:/usr/share/}"
export XDG_CONFIG_DIRS="${XDG_CONFIG_DIRS:=/etc/xdg}"

# Point zsh at $XDG_CONFIG_HOME/zsh for its dotfiles.
export ZDOTDIR="${ZDOTDIR:=$XDG_CONFIG_HOME/zsh}"

# Ensure that a non-login, non-interactive shell has a defined environment.
if [[ ( "$SHLVL" -eq 1 && ! -o LOGIN ) && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi
