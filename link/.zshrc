includes=(~/.zgenom/zgenom.zsh)
zsh_plugins=(subnixr/minimal)
oh_my_zsh_plugins=(zsh-fzf-history-search)

path=(
  $HOME/.bin
  $HOME/.local/bin
  $HOME/.bun/bin
  $HOME/.bun/_bun
  $HOME/Library/Python/3.9/bin
  /opt/homebrew/bin
  /opt/homebrew/opt/coreutils/libexec/gnubin
  /opt/homebrew/opt/gnu-sed/libexec/gnubin
  /opt/homebrew/opt/grep/libexec/gnubin
  /opt/homebrew/opt/node@20/bin
  /opt/homebrew/sbin
  $path
)

fpath=(
  /opt/homebrew/share/zsh/site-functions
  $fpath
)

_fzf_compgen_path() {
  ag --hidden --smart-case -g .
}

eval "$(brew shellenv)"
eval "$(fzf --zsh)"

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
alias ls="eza --group-directories-first --git"
alias v="nvim"

for i in "${includes[@]}"; do
  [ -f "$i" ] && source "$i"
done

zgenom autoupdate

if ! zgenom saved; then
  for i in "${zsh_plugins[@]}"; do
    zgenom load "$i"
  done

  for i in "${oh_my_zsh_plugins[@]}"; do
    zgenom ohmyzsh "$i"
  done

  zgenom save
fi

gpgconf --launch gpg-agent
gpg-connect-agent updatestartuptty /bye &> /dev/null
