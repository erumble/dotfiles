#!/usr/bin/env zsh

# Install Xcode Command Line Tools (Homebrew and git depend on them). The
# installer is a GUI popup that runs async, so wait for it before continuing.
if ! xcode-select -p &>/dev/null; then
  xcode-select --install
  until xcode-select -p &>/dev/null; do sleep 5; done
fi

# Install Homebrew
if [[ ! -f /opt/homebrew/bin/brew ]]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
brew bundle

# Set XDG vars (these will be set by $HOME/.zshenv after this is run for the first time)
cfg_src=${0:a:h}/config
source $cfg_src/zsh/.zshenv

# ZDOTDIR needs to get set before zsh will respect $XDG_CONFIG_HOME/zsh
if [[ ! -f $HOME/.zshenv ]]; then
  ln -s $cfg_src/zsh/.zshenv $HOME/.zshenv
fi

# Neovim's plugin manager (lazy.nvim) self-bootstraps on first launch, and mason
# installs language servers on demand, so there's nothing to install here.

# Symlink config into $XDG_CONFIG_HOME.
#
# A directory containing a `.symlink` marker is linked as a single unit, so new
# files inside it appear automatically (handy for your own script dirs like
# bin/). Everything else is linked file-by-file, which keeps tool-written state
# (gh tokens, caches, lockfiles) out of this repo.
setopt EXTENDED_GLOB

link() {  # link <source> <target>; never clobbers an existing path
  local src=$1 dst=$2
  [[ -e $dst || -L $dst ]] && return
  mkdir -p ${dst:h}
  ln -s $src $dst
  print "linked ${dst/#$HOME/~} -> ${src/#$HOME/~}"
}

# 1. Whole-directory links: dirs marked with a .symlink file (:h -> the dir).
typeset -a link_dirs
link_dirs=(${cfg_src}/**/.symlink(N:h))
for dir in $link_dirs; do
  link $dir $XDG_CONFIG_HOME/${dir#$cfg_src/}
done

# 2. Everything else, file-by-file — skipping READMEs, markers, and anything
#    already inside a marked directory.
for file in ${cfg_src}/**/^README.md(.ND); do
  [[ ${file:t} == .symlink ]] && continue
  for dir in $link_dirs; do [[ $file == $dir/* ]] && continue 2; done
  link $file $XDG_CONFIG_HOME/${file#$cfg_src/}
done

# macOS system setup. Each step is guarded so re-running is a no-op.

# Touch ID for sudo. sudo_local is a user file that survives OS updates, unlike
# editing /etc/pam.d/sudo directly (which macOS clobbers on every upgrade).
# pam_reattach must precede pam_tid so Touch ID also works inside tmux.
if [[ -f /etc/pam.d/sudo_local.template && ! -f /etc/pam.d/sudo_local ]]; then
  print "enabling Touch ID for sudo (tmux-aware)"
  sudo tee /etc/pam.d/sudo_local >/dev/null <<'EOF'
auth       optional       /opt/homebrew/lib/pam/pam_reattach.so
auth       sufficient     pam_tid.so
EOF
fi

# Application firewall. Setting it on when already on is harmless, but guard to
# avoid a needless sudo prompt.
if [[ $(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate) != *enabled* ]]; then
  print "enabling application firewall"
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on >/dev/null
fi

# Automatic security update checks.
sudo softwareupdate --schedule on >/dev/null

# FileVault requires a reboot and a recovery key, so don't force it — just warn.
if ! fdesetup status | grep -q "FileVault is On"; then
  print "WARNING: FileVault is off. Enable it: sudo fdesetup enable"
fi

