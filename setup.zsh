#!/usr/bin/env zsh

# Supports macOS and Fedora Workstation (GNOME). CLI tools come from Homebrew
# on both platforms (one shared Brewfile); GUI apps are casks on macOS and
# dnf/flatpak installs on Fedora.
case "$OSTYPE" in
  darwin*) platform=macos ;;
  linux*)
    if grep -qs '^ID=fedora' /etc/os-release; then
      platform=fedora
    else
      print -u2 "unsupported Linux distro; only Fedora is supported"
      exit 1
    fi
    ;;
  *)
    print -u2 "unsupported platform: $OSTYPE"
    exit 1
    ;;
esac

if [[ $platform == macos ]]; then
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
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  # Homebrew's Linux build dependencies, plus dnf5-plugins for `dnf copr`
  # below and wl-clipboard for the pbcopy-style aliases in .zshrc.
  sudo dnf group install -y development-tools
  sudo dnf install -y procps-ng curl file git dnf5-plugins wl-clipboard

  # Install Homebrew (same installer as macOS; it lands in /home/linuxbrew)
  if [[ ! -f /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

  # VS Code from Microsoft's repo. Must precede `brew bundle` so the vscode
  # extension entries in the Brewfile have a `code` CLI to install through.
  if [[ ! -f /etc/yum.repos.d/vscode.repo ]]; then
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo tee /etc/yum.repos.d/vscode.repo >/dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
  fi

  # 1Password from its official repo (not packaged by Fedora).
  if [[ ! -f /etc/yum.repos.d/1password.repo ]]; then
    sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
    sudo tee /etc/yum.repos.d/1password.repo >/dev/null <<'EOF'
[1password]
name=1Password Stable Channel
baseurl=https://downloads.1password.com/linux/rpm/stable/$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://downloads.1password.com/linux/keys/1password.asc
EOF
  fi

  # Ghostty ships via COPR (the repo ghostty.org points Fedora users at).
  sudo dnf copr enable -y scottames/ghostty

  sudo dnf install -y code 1password ghostty

  # GUI apps that only ship as flatpaks. Firefox comes preinstalled on Fedora
  # GNOME. No Linux equivalent for battle-net, gpg-suite, kaleidoscope,
  # linearmouse, orbstack, or rectangle (GNOME tiles windows natively).
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  flatpak install -y --noninteractive flathub \
    com.discordapp.Discord \
    com.google.Chrome \
    com.spotify.Client \
    com.valvesoftware.Steam \
    rest.insomnia.Insomnia \
    us.zoom.Zoom

  # Claude Code (a cask on macOS; native installer elsewhere)
  if ! command -v claude &>/dev/null && [[ ! -x $HOME/.local/bin/claude ]]; then
    curl -fsSL https://claude.ai/install.sh | bash
  fi

  # Hack Nerd Font (a cask on macOS; ghostty's font-family expects it)
  font_dir=$HOME/.local/share/fonts/HackNerdFont
  if [[ ! -d $font_dir ]]; then
    mkdir -p $font_dir
    curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.tar.xz \
      | tar -xJ -C $font_dir
    fc-cache -f $font_dir
  fi
fi

brew bundle --file=${0:a:h}/Brewfile

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

if [[ $platform == macos ]]; then
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
else
  # Fedora system setup. Each step is guarded so re-running is a no-op.

  # firewalld ships enabled on Fedora Workstation, but make sure.
  if ! systemctl is-active -q firewalld; then
    print "enabling firewalld"
    sudo systemctl enable --now firewalld
  fi

  # Automatic update checks (GNOME Software also notifies in GUI sessions).
  if ! systemctl is-enabled -q dnf5-automatic.timer 2>/dev/null; then
    print "enabling automatic update checks"
    sudo dnf install -y dnf5-plugin-automatic
    sudo systemctl enable --now dnf5-automatic.timer
  fi

  # Disk encryption is an install-time choice on Fedora, so just warn.
  if ! lsblk -rno TYPE | grep -q crypt; then
    print "WARNING: no LUKS-encrypted volume found. Encryption requires a reinstall."
  fi
fi
