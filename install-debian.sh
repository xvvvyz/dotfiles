#!/usr/bin/env bash

set -e

source "$(dirname "$0")/link/.bin/utilities/config"
source "$(dirname "$0")/link/.bin/utilities/env"
source "$(dirname "$0")/link/.bin/utilities/fancy-print"
source "$(dirname "$0")/link/.bin/utilities/fancy-ask"

GLOBIGNORE=".:.."

fancy_print "installing bootstrap packages..."
sudo apt update
sudo apt install -y ca-certificates curl git unzip

if [[ -d ~/.config && ! -L ~/.config ]]; then
  fancy_print "merging .config files..."
  cp -npr ~/.config/* link/.config || true
  rm -rf ~/.config
fi

fancy_print "removing existing .gnupg/.ssh..."
[[ -L ~/.gnupg ]] || rm -rf ~/.gnupg
[[ -L ~/.ssh ]] || rm -rf ~/.ssh

fancy_print "symlinking dotfiles..."
ln -svfn "$(pwd)/link/."??* ~

fancy_print "symlinking pinentry to /usr/local/bin..."
mkdir -p /usr/local/bin
sudo ln -svfn ~/.bin/pinentry /usr/local/bin/pinentry


fancy_print "installing fzf..."
git clone --depth 1 https://github.com/junegunn/fzf.git "$fzf_dir" 2>/dev/null || true
"$fzf_dir/install" --no-key-bindings --no-completion --no-update-rc --no-bash --no-zsh --no-fish

fancy_print "installing zgenom..."
git clone https://github.com/jandamm/zgenom.git "$zgen_dir" 2>/dev/null || true

fancy_print "adding docker sources..."
sudo rm -f /etc/apt/sources.list.d/docker*.list /etc/apt/sources.list.d/docker*.sources
sudo rm -f /etc/apt/keyrings/docker.gpg /etc/apt/keyrings/docker.asc
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

fancy_print "updating apt cache..."
sudo apt update

fancy_print "installing apt packages..."
xargs -a "${list_file_apt_packages}" sudo apt-get install -y

if is_wsl; then
  # no logind seat in wsl, so the uaccess tag from 60-scdaemon.rules never applies.
  fancy_print "adding yubikey udev rule..."
  sudo tee /etc/udev/rules.d/70-yubikey.rules <<EOF
SUBSYSTEM=="usb", ATTR{idVendor}=="1050", GROUP="plugdev", MODE="0660"
EOF
  sudo udevadm control --reload
  sudo udevadm trigger --subsystem-match=usb --action=add
fi

fancy_print "setting zsh as default shell..."
chsh -s "$(command -v zsh)" "$USER"

fancy_print "installing bun..."
chmod a-w ~/.zshrc
curl -fsSL https://bun.sh/install | bash
chmod u+w ~/.zshrc

export PATH="$HOME/.bun/bin:$HOME/.local/bin:$PATH"

fancy_print "installing bun packages..."
xargs bun i -g < "${list_file_bun_packages}"

fancy_print "installing neovim..."
nvim_version=$(curl -fsSL "https://api.github.com/repos/neovim/neovim/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
nvim_dir="$HOME/.local/lib/neovim"
rm -rf "$nvim_dir"
mkdir -p "$nvim_dir"
curl -fsSL "https://github.com/neovim/neovim/releases/download/${nvim_version}/nvim-linux-x86_64.tar.gz" | tar xz --strip-components=1 -C "$nvim_dir"
mkdir -p "$HOME/.local/bin"
ln -svfn "$nvim_dir/bin/nvim" "$HOME/.local/bin/nvim"

fancy_print "installing lua-language-server..."
lua_ls_version=$(curl -fsSL "https://api.github.com/repos/LuaLS/lua-language-server/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
lua_ls_dir="$HOME/.local/lib/lua-language-server"
mkdir -p "$lua_ls_dir"
curl -fsSL "https://github.com/LuaLS/lua-language-server/releases/download/${lua_ls_version}/lua-language-server-${lua_ls_version}-linux-x64.tar.gz" | tar xz -C "$lua_ls_dir"
ln -svfn "$lua_ls_dir/bin/lua-language-server" "$HOME/.local/bin/lua-language-server"

if is_wsl; then
  winget_install() {
    # winget eats stdin, which would consume the caller's loop input.
    winget.exe install -e --id "$1" --source "${2:-winget}" --accept-package-agreements --accept-source-agreements < /dev/null || true
  }

  fancy_print "installing winget packages..."
  while IFS= read -r pkg || [[ -n "$pkg" ]]; do
    [[ -n "$pkg" ]] && winget_install "$pkg"
  done < "${list_file_winget_packages}"

  if has_nvidia_gpu; then
    # published to the microsoft store only, not the winget source.
    fancy_print "installing nvidia app..."
    winget_install XP8CLZL93F5Z4P msstore
  fi

  if [[ -n "$win_appdata_local" ]]; then
    fancy_print "staging windows setup..."
    win_stage="${win_appdata_local}/Temp/dotfiles"
    rm -rf "$win_stage"
    mkdir -p "$win_stage"
    cp install-windows.ps1 "${list_file_windows_apps}" "$win_stage"
    cp -r "${copy_dir}/AppData" "$win_stage"

    fancy_print "running windows setup..."
    # -Wait would also wait on descendants, including the powertoys it starts.
    powershell.exe -NoProfile -Command "(Start-Process powershell -Verb RunAs -PassThru -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"$(wslpath -w "$win_stage/install-windows.ps1")\"').WaitForExit()" || true

    # windows 11 blocks setting the default browser silently; this opens the
    # settings page for the remaining click. unelevated on purpose.
    fancy_print "opening default browser settings..."
    (cd /mnt/c && cmd.exe /C start "" "C:\Program Files\Mozilla Firefox\firefox.exe" -setDefaultBrowser) || true
  fi

  fancy_print "installing win32yank..."
  win32yank_url=$(curl -fsSL "https://api.github.com/repos/equalsraf/win32yank/releases/latest" | grep -Po '"browser_download_url": "\K[^"]*x64[^"]*')
  curl -fsSL "$win32yank_url" -o /tmp/win32yank.zip
  unzip -o /tmp/win32yank.zip -d /tmp/win32yank
  chmod +x /tmp/win32yank/win32yank.exe
  mv /tmp/win32yank/win32yank.exe "$HOME/.local/bin/win32yank.exe"
  rm -rf /tmp/win32yank /tmp/win32yank.zip
fi

fancy_print "installing neovim plugins..."
nvim --headless '+Lazy! sync' +qa

fancy_print "updating dotfiles remote..."
git remote remove origin 2>/dev/null || true
git remote add --mirror=push origin git@github.com:xvvvyz/dotfiles.git 2>/dev/null || true

fancy_print "done!"
