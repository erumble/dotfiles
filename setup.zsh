#!/usr/bin/env zsh

set -x

# Set XDG vars (these will be set by $HOME/.zshenv after this is run for the first time)
cfg_src=${0:a:h}/config
source $cfg_src/zsh/.zshenv

# Install Prezto
prezto_dir=$XDG_CONFIG_HOME/zsh/.zprezto
if [[ ! -d $prezto_dir ]]; then
  git clone --recursive https://github.com/sorin-ionescu/prezto.git $prezto_dir
fi

# ZDOTDIR needs to get set before zsh will respect $XDG_CONFIG_HOME/zsh
if [[ ! -f $HOME/.zshenv ]]; then
  ln -s $cfg_src/zsh/.zshenv $HOME/.zshenv
fi

# Install Vim Plug
vimplug_dir=$XDG_CONFIG_HOME/nvim/.vim-plug
if [[ ! -d $vimplug_dir ]]; then
  git clone https://github.com/junegunn/vim-plug.git $vimplug_dir
fi

vimplug_autoload_dir=$XDG_DATA_HOME/nvim/site/autoload
if [[ ! -f $vimplug_autoload_dir/plug.vim ]]; then
  mkdir -p $vimplug_autoload_dir
  ln -s $vimplug_dir/plug.vim $vimplug_autoload_dir/plug.vim
fi

# Symlink config files
setopt EXTENDED_GLOB
cfg_files=(${cfg_src}/**/^README.md(.ND))
cfg_files=(${(@)cfg_files#$cfg_src/})

for cfg_file in ${(@)cfg_files}; do
  if [[ ! -d $(dirname $XDG_CONFIG_HOME/$cfg_file) ]]; then
    mkdir -p $(dirname $XDG_CONFIG_HOME/$cfg_file)
  fi

  if [[ ! -f $XDG_CONFIG_HOME/$cfg_file ]]; then
    ln -s $cfg_src/$file $XDG_CONFIG_HOME/$cfg_file
  fi
done

