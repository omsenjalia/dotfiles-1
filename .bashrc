

# Commands that should be applied only for interactive shells.
[[ $- == *i* ]] || return

HISTFILE="/home/om/.local/state/bash/history"
HISTFILESIZE=1000
HISTSIZE=100
mkdir -p "$(dirname "$HISTFILE")"

shopt -s cdspell
shopt -s checkjobs
shopt -s checkwinsize
shopt -s dirspell
shopt -s globstar
shopt -s histappend
shopt -s no_empty_cmd_completion

alias df='df -h'
alias eza='eza --icons auto --group --group-directories-first --header --no-permissions --octal-permissions'
alias fd='fd --hidden'
alias jctl='journalctl -p 3 -xb'
alias la='eza -a'
alias lg=lazygit
alias ll='eza -l'
alias lla='eza -la'
alias ls=eza
alias lt='eza --tree'
alias mkdir='mkdir -pv'
alias rs='systemctl reboot'
alias zzzbk='cd ~/.local/share/zzz ; git add . ; git commit -m '\''chore: sync changes'\'' ; git push ; cd -'
alias zzzpl='cd ~/.local/share/zzz ; git pull ; git push ; cd -'

if [[ ! -v BASH_COMPLETION_VERSINFO ]]; then
  . "/nix/store/wcy3wahf6bpivn0clm94inv26mvqbkb8-bash-completion-2.17.0/etc/profile.d/bash_completion.sh"
fi

if [[ -n "${GHOSTTY_RESOURCES_DIR}" ]]; then
  builtin source "${GHOSTTY_RESOURCES_DIR}/shell-integration/bash/ghostty.bash"
fi

if [[ :$SHELLOPTS: =~ :(vi|emacs): ]]; then
  eval "$(/nix/store/8jrz43k4f0fx07rffm4mc5wa90xhdcs0-fzf-0.68.0/bin/fzf --bash)"
fi

if [[ :$SHELLOPTS: =~ :(vi|emacs): ]]; then
  eval "$(/nix/store/vwy0pl0183g9p178pjx0icid9rs7jbx3-navi-2.24.0/bin/navi widget bash)"
fi

function lg() {
    export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir
    command lazygit "$@"
    if [ -f $LAZYGIT_NEW_DIR_FILE ]; then
      cd "$(cat $LAZYGIT_NEW_DIR_FILE)"
      rm -f $LAZYGIT_NEW_DIR_FILE > /dev/null
    fi
}

if [[ :$SHELLOPTS: =~ :(vi|emacs): ]]; then
  source "/nix/store/vazwpr8jdn45q5lrfp1gxa0vsrb94zxx-bash-preexec-0.6.0/share/bash/bash-preexec.sh"
  eval "$(/nix/store/q5zwmzl587wfcpqgixq4gydw8qkcxrs7-atuin-18.12.1/bin/atuin init bash --disable-up-arrow)"
fi

eval "$(/nix/store/facg208fw2bgsg7w0f13k5iwkp8lnsi4-direnv-2.37.1/bin/direnv hook bash)"

if [[ $TERM != "dumb" ]]; then
  eval "$(/nix/store/s3fniw0gqhh5vl9w3v8yj5bd0hqi5nj2-starship-1.24.2/bin/starship init bash --print-full-init)"
fi

eval "$(/nix/store/bgzs7s82drfwanhmkj2lfim8xn2yzmw6-zoxide-0.9.9/bin/zoxide init bash --cmd cd)"

