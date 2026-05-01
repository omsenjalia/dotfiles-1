

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
  . "/nix/store/m77c5prggf0vk6x5gxbpmmlk1klpsavp-bash-completion-2.17.0/etc/profile.d/bash_completion.sh"
fi

if [[ -n "${GHOSTTY_RESOURCES_DIR}" ]]; then
  builtin source "${GHOSTTY_RESOURCES_DIR}/shell-integration/bash/ghostty.bash"
fi

if [[ :$SHELLOPTS: =~ :(vi|emacs): ]]; then
  eval "$(/nix/store/1fc3iszabni2f7rnvdx49db2350qck7n-fzf-0.72.0/bin/fzf --bash)"
fi

if [[ :$SHELLOPTS: =~ :(vi|emacs): ]]; then
  eval "$(/nix/store/5zdjq222llhvn0mlws3z4jl7m4jyrxb3-navi-2.24.0/bin/navi widget bash)"
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
  source "/nix/store/v1z7qhhgvm4fs7c7z285d605bb734hva-bash-preexec-0.6.0/share/bash/bash-preexec.sh"
  eval "$(/nix/store/zc6bcyyi4il7289fyzxldnc9iphkwxsb-atuin-18.15.2/bin/atuin init bash --disable-up-arrow)"
fi

eval "$(/nix/store/m9csyivb7b2d6bp7blb0sdc9mmqaypf3-direnv-2.37.1/bin/direnv hook bash)"

if [[ $TERM != "dumb" ]]; then
  eval "$(/nix/store/bmwjw58xl4isgsbwy3dr5sixj1afrkrs-starship-1.24.2/bin/starship init bash --print-full-init)"
fi

eval "$(/nix/store/48wm0a2qb8q96fmlyj3cbfxj7h8bqfbf-zoxide-0.9.9/bin/zoxide init bash --cmd cd)"

