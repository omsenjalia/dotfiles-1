

# Commands that should be applied only for interactive shells.
[[ $- == *i* ]] || return

HISTFILE="/home/isabel/.local/state/bash/history"
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

alias -- df='df -h'
alias -- eza='eza --icons auto --group --group-directories-first --header --no-permissions --octal-permissions'
alias -- fd='fd --hidden'
alias -- jctl='journalctl -p 3 -xb'
alias -- la='eza -a'
alias -- lg=lazygit
alias -- ll='eza -l'
alias -- lla='eza -la'
alias -- ls=eza
alias -- lt='eza --tree'
alias -- mkdir='mkdir -pv'
alias -- rs='systemctl reboot'
alias -- zzzbk='cd ~/.local/share/zzz ; git add . ; git commit -m '\''chore: sync changes'\'' ; git push ; cd -'
alias -- zzzpl='cd ~/.local/share/zzz ; git pull ; git push ; cd -'

if [[ ! -v BASH_COMPLETION_VERSINFO ]]; then
  . "/nix/store/wcy3wahf6bpivn0clm94inv26mvqbkb8-bash-completion-2.17.0/etc/profile.d/bash_completion.sh"
fi

if [[ -n "${GHOSTTY_RESOURCES_DIR}" ]]; then
  builtin source "${GHOSTTY_RESOURCES_DIR}/shell-integration/bash/ghostty.bash"
fi

if [[ :$SHELLOPTS: =~ :(vi|emacs): ]]; then
  eval "$(/nix/store/bqz2sllks58anmkms91fynijx1xvvi8a-fzf-0.70.0/bin/fzf --bash)"
fi

if [[ :$SHELLOPTS: =~ :(vi|emacs): ]]; then
  eval "$(/nix/store/p6h2wblpal0s9dylgfv1r3qc82pkavim-navi-2.24.0/bin/navi widget bash)"
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
  source "/nix/store/cpafbj895hib6bapp2ybs8y28fcji3xl-bash-preexec-0.6.0/share/bash/bash-preexec.sh"
  eval "$(/nix/store/q5zwmzl587wfcpqgixq4gydw8qkcxrs7-atuin-18.12.1/bin/atuin init bash --disable-up-arrow)"
fi

eval "$(/nix/store/facg208fw2bgsg7w0f13k5iwkp8lnsi4-direnv-2.37.1/bin/direnv hook bash)"

if [[ $TERM != "dumb" ]]; then
  eval "$(/nix/store/s3fniw0gqhh5vl9w3v8yj5bd0hqi5nj2-starship-1.24.2/bin/starship init bash --print-full-init)"
fi

eval "$(/nix/store/y2jp6fwbsbfvqd4clr4jcx7455ainfll-zoxide-0.9.9/bin/zoxide init bash --cmd cd)"

