#!/usr/bin/env zsh

source "$(dirname "$0")/link/.bin/utilities/config"
source "$(dirname "$0")/link/.bin/utilities/fancy-print"
source "$(dirname "$0")/link/.bin/utilities/fancy-ask"

GLOBIGNORE=".:.."

if [[ -d ~/.gnupg ]]; then
  fancy_print "removing existing .gnupg..."
  rm -rf ~/.gnupg
fi

if [[ -d ~/.config ]]; then
  fancy_print "merging .config files..."
  cp -npr ~/.config/* link/.config
  rm -rf ~/.config
fi

fancy_print "setting defaults..."
defaults write -g InitialKeyRepeat -int 15
defaults write -g KeyRepeat -int 1
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-time-modifier -int 0
defaults write com.apple.dock mineffect -string scale
defaults write com.apple.dock orientation -string left
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.screencapture disable-shadow -bool true
defaults write com.apple.screencapture show-thumbnail -bool false
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.TextEdit RichText -bool false
sudo defaults write /Library/Preferences/com.apple.loginwindow DisableFDEAutoLogin -bool YES
killall Dock
killall Finder

fancy_print "symlinking dotfiles..."
ln -svfn "$(pwd)/link/."??* ~

fancy_print "fixing permissions..."
chmod 700 ~/.gnupg
find ~/.gnupg -type f -exec chmod 600 {} \;

fancy_print "installing homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

fancy_print "tapping brew repos..."
brew tap homebrew/cask-drivers
brew tap homebrew/cask-fonts
brew tap homebrew/cask-versions

fancy_print "installing brew packages..."
xargs brew install < "${list_file_brew_packages}"

fancy_print "installing brew casks..."
xargs brew install --cask < "${list_file_brew_casks}"

fancy_print "installing yarn packages..."
xargs yarn global add < "${list_file_yarn_packages}"

fancy_print "installing python packages..."
xargs pip3 install < "${list_file_python_packages}"

fancy_print "installing zgen..."
git clone https://github.com/tarjoilija/zgen.git "$zgen_dir"

fancy_print "installing vim-plug..."
curl --create-dirs -fsSLo ~/.local/share/nvim/site/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

fancy_print "installing neovim plugins..."
nvim -c 'PlugInstall' -c 'UpdateRemotePlugins' -c 'qa!'

fancy_print "starting brew services..."
brew services start yabai
brew services start skhd

fancy_print "done!"
