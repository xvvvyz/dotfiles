#!/usr/bin/env bash

set -e

source "$(dirname "$0")/link/.bin/utilities/config"
source "$(dirname "$0")/link/.bin/utilities/fancy-print"
source "$(dirname "$0")/link/.bin/utilities/fancy-ask"

GLOBIGNORE=".:.."

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

fancy_print "installing curl..."

fancy_print "adding docker sources..."
sudo rm -f /etc/apt/sources.list.d/docker*.list /etc/apt/sources.list.d/docker*.sources
sudo rm -f /etc/apt/keyrings/docker.gpg /etc/apt/keyrings/docker.asc
sudo apt update
sudo apt install ca-certificates curl
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

fancy_print "setting zsh as default shell..."
chsh -s "$(command -v zsh)" "$USER"

fancy_print "installing bun..."
chmod a-w ~/.zshrc
curl -fsSL https://bun.sh/install | bash
chmod u+w ~/.zshrc

fancy_print "installing bun packages..."
xargs bun i -g < "${list_file_bun_packages}" || true

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

fancy_print "installing claude code..."
curl -fsSL https://claude.ai/install.sh | bash

if grep -qi microsoft /proc/version; then
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
