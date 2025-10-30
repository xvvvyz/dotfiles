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

fancy_print "symlinking dotfiles (excluding .gnupg)..."
ln -svfn "$(pwd)/link/."??* ~
rm -f ~/.gnupg

fancy_print "installing zgenom..."
git clone https://github.com/jandamm/zgenom.git "$zgen_dir" 2>/dev/null || true

fancy_print "updating apt cache..."
sudo apt update

fancy_print "installing apt packages..."
xargs -a "${list_file_apt_packages}" sudo apt-get install -y

fancy_print "setting zsh as default shell..."
chsh -s "$(command -v zsh)" "$USER"

fancy_print "installing bun..."
curl -fsSL https://bun.sh/install | bash

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
