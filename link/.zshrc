_fzf_compgen_path() { ag --hidden --smart-case -g .; }

includes=(~/.zgen/zgen.zsh)
zsh_plugins=(subnixr/minimal)
oh_my_zsh_plugins=(plugins/fzf)

path=(
  $HOME/.bin
  $HOME/.cargo/bin
  $HOME/.local/bin
  /opt/homebrew/bin
  /opt/homebrew/opt/coreutils/libexec/gnubin
  /opt/homebrew/opt/gnu-sed/libexec/gnubin
  /opt/homebrew/opt/grep/libexec/gnubin
  /opt/homebrew/sbin
  $path
)

fpath=(
  /opt/homebrew/share/zsh/site-functions
  $fpath
)

unset HISTFILESIZE

export EDITOR="nvim"
export FZF_COMPLETION_TRIGGER="**"
export FZF_DEFAULT_COMMAND="ag --vimgrep --hidden --smart-case -g ."
export FZF_DEFAULT_OPTS="--exact --inline-info"
export GPG_TTY="$(tty)"
export GREP_COLOR="1;32"
export HISTDUP=erase
export HISTFILE=~/.zsh_history
export HISTSIZE=10000000
export MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"
export SAVEHIST=10000000
export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
export VISUAL="nvim"
export ZGEN_RESET_ON_CHANGE=("$HOME/.zshrc")

setopt appendhistory
setopt incappendhistory
setopt sharehistory

bindkey -e

alias grep="grep --color=auto"
alias ls="exa --group-directories-first --git"
alias v="nvim"

for i in "${includes[@]}"; do [ -f "$i" ] && source "$i"; done

if ! zgen saved; then
  zgen selfupdate
  for i in "${zsh_plugins[@]}"; do zgen load "$i"; done
  for i in "${oh_my_zsh_plugins[@]}"; do zgen oh-my-zsh "$i"; done
  zgen update
  zgen save
fi

gpgconf --launch gpg-agent
gpg-connect-agent updatestartuptty /bye &> /dev/null
