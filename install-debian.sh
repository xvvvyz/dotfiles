#!/usr/bin/env bash

set -e

source "$(dirname "$0")/link/.bin/utilities/config"
source "$(dirname "$0")/link/.bin/utilities/fancy-print"
source "$(dirname "$0")/link/.bin/utilities/fancy-ask"

GLOBIGNORE=".:.."

if [[ -d ~/.config ]]; then
  fancy_print "merging .config files..."
  cp -npr ~/.config/* link/.config || true
  rm -rf ~/.config
fi

fancy_print "removing existing .gnupg/.ssh..."
rm -rf ~/.gnupg ~/.ssh

fancy_print "symlinking dotfiles..."
ln -svfn "$(pwd)/link/."??* ~

fancy_print "symlinking pinentry to /usr/local/bin..."
mkdir -p /usr/local/bin
sudo ln -svfn ~/.bin/pinentry /usr/local/bin/pinentry

fancy_print "removing unused symlinks..."
rm -f ~/.docker
grep -qi microsoft /proc/version || rm -f ~/.gnupg

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
xargs bun i -g < "${list_file_bun_packages}"

fancy_print "installing vim-plug..."
curl --create-dirs -fsSLo ~/.local/share/nvim/site/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

fancy_print "installing neovim plugins..."
nvim -c 'PlugInstall' -c 'UpdateRemotePlugins' -c 'qa!'

fancy_print "updating dotfiles remote..."
git remote remove origin || true
git remote add --mirror=push origin git@github.com:xvvvyz/dotfiles.git

fancy_print "done!"
