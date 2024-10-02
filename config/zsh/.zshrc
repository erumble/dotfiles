#
# Executes commands at the start of an interactive session.
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Color ls
export CLICOLOR=1
export LSCOLORS=ExFxCxDxBxegedabagacad

# setup brew if available
if command -v /opt/homebrew/bin/brew &>/dev/null; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

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

# Aliases for non-native tools
declare -A extAliases
extAliases=(
  [ag]="ag --hidden --ignore .git/ --ignore .terraform/"
  [cat]="bat"
  [cdiff]="colordiff -u"
  [kc]="kubectl"
  [kctx]="kubectx"
  [kcns]="kubens"
  [ll]="eza -aghl --color-scale --git"
  [rg]="rg --hidden -g '!.git' -g '!.terraform'"
  [tf]="terraform"
  [tfdocs]="terraform-docs"
  [tree]="tree -I vendor -I .terraform -I .git -a"
  [vi]="nvim"
)

for key value in ${(kv)extAliases}; do
  cmd=$(awk '{print $1}' <<< $value)

  if command -v $cmd &>/dev/null; then
    alias $key=$value
  fi
done

