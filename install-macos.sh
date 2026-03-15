#!/usr/bin/env zsh

set -eo pipefail

source "$(dirname "$0")/link/.bin/utilities/config"
source "$(dirname "$0")/link/.bin/utilities/fancy-print"
source "$(dirname "$0")/link/.bin/utilities/fancy-ask"

GLOBIGNORE=".:.."

fancy_print "setting defaults..."
defaults write -g ApplePressAndHoldEnabled -bool false
defaults write -g InitialKeyRepeat -int 15
defaults write -g KeyRepeat -int 1
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.TextEdit RichText -bool false
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-time-modifier -int 0
defaults write com.apple.dock mineffect -string scale
defaults write com.apple.dock orientation -string left
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.screencapture disable-shadow -bool true
defaults write com.apple.screencapture show-thumbnail -bool false
sudo defaults write /Library/Preferences/com.apple.loginwindow DisableFDEAutoLogin -bool YES
sudo pmset -a hibernatemode 25
sudo pmset -a standbydelay 15
killall Dock
killall Finder

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

fancy_print "installing zgenom..."
git clone https://github.com/jandamm/zgenom.git "$zgen_dir" 2>/dev/null || true

fancy_print "sourcing ~/.zshrc"
source ~/.zshrc

fancy_print "installing homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

fancy_print "installing brew packages..."
xargs brew install < "${list_file_brew_packages}" || true

fancy_print "installing brew casks..."
while read -r cask; do
  brew list --cask "$cask" &>/dev/null || brew install --cask "$cask"
done < "${list_file_brew_casks}"

fancy_print "installing bun packages..."
xargs bun i -g < "${list_file_bun_packages}" || true

fancy_print "installing uv tools..."
xargs uv pip tool < "${list_file_uv_tools}" || true

fancy_print "installing neovim plugins..."
nvim --headless '+Lazy! sync' +qa

fancy_print "updating dotfiles remote..."
git remote remove origin 2>/dev/null || true
git remote add --mirror=push origin git@github.com:xvvvyz/dotfiles.git 2>/dev/null || true

fancy_print "done!"
