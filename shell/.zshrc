########################
# OH MY ZSH
########################

if [[ -d "$HOME/.oh-my-zsh" ]]; then
  export ZSH="$HOME/.oh-my-zsh"

  ZSH_THEME="robbyrussell"

  plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

  source "$ZSH/oh-my-zsh.sh"
fi

########################
# HISTORY
########################

HISTSIZE=5000
SAVEHIST=5000
HISTFILE=~/.zsh_history

setopt appendhistory
setopt sharehistory
setopt hist_ignore_dups
setopt hist_ignore_space

########################
# OPTIONS
########################

setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS

########################
# COMPLETION
########################

if [[ -o interactive ]]; then
  if [ -d ~/.zsh/zsh-completions/src ]; then
    fpath=(~/.zsh/zsh-completions/src $fpath)
  fi
  autoload -Uz compinit && compinit
fi

########################
# EDITOR
########################

export EDITOR=nvim

########################
# PATH
########################

[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"
[ -d "$HOME/.npm-global/bin" ] && export PATH="$HOME/.npm-global/bin:$PATH"

########################
# ALIASES
########################

if [[ -o interactive ]]; then

  alias cd="z"

  alias cat='bat --paging=never'

  alias v='nvim'
  alias 'v.'='nvim -c Oil'

  alias e="exit"

  alias cls="clear"

  alias nta="tmux attach -t"

  alias ntm='tmux new-session -s'

  alias off="sudo systemctl poweroff"

  alias reboot="sudo systemctl reboot"

  alias vspeaker='pactl list short sinks | grep -q virtual_speaker || pactl load-module module-null-sink sink_name=virtual_speaker sink_properties=device.description=VirtualSpeaker'

  alias gpush='rclone sync /home/muggle/hlt/obsidian gdrive:obsidian \
    --exclude ".obsidian/cache/**" \
    --exclude ".trash/**" \
    --progress'

  alias gpull='rclone sync gdrive:obsidian /home/muggle/hlt/obsidian \
    --exclude ".obsidian/cache/**" \
    --exclude ".trash/**" \
    --progress'

  alias resetgg='rm -rf ~/.config/google-chrome/Singleton*'

  alias cardon='sudo nvidia-smi -pm 1'

  alias cardoff='sudo nvidia-smi -pm 0'

  alias ud='sudo dnf update'

fi

########################
# ZOXIDE
########################

if [[ -o interactive ]]; then
  eval "$(zoxide init zsh)"
fi

########################
# HISTORY SEARCH
########################

if [[ -o interactive ]] && [ -f ~/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh ]; then
  source ~/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
fi

########################
# FZF
########################

if [[ -o interactive ]]; then
  [ -f /usr/share/fzf/shell/key-bindings.zsh ] && source /usr/share/fzf/shell/key-bindings.zsh
  [ -f /usr/share/fzf/shell/completion.zsh ] && source /usr/share/fzf/shell/completion.zsh

  export FZF_FD_COMMON_OPTS='--hidden --follow --strip-cwd-prefix --exclude .git --exclude .cache --exclude node_modules --exclude .npm --exclude .venv --exclude __pycache__'
  export FZF_DEFAULT_COMMAND="fd ${FZF_FD_COMMON_OPTS} --type f ."
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="fd ${FZF_FD_COMMON_OPTS} --type d ."

  export FZF_CTRL_T_OPTS='--scheme=path --preview "bat --color=always --style=numbers --line-range=:200 {}"'
  export FZF_ALT_C_OPTS='--scheme=path --preview "eza --tree --level=1 --color=always {}"'

  unset FZF_DEFAULT_OPTS

  alias f=fzf
  alias fp='fzf --preview="bat --color=always {}"'

  fv() {
    local file
    file=$(fd ${=FZF_FD_COMMON_OPTS} --type f . | fzf --scheme=path --preview='bat --color=always --style=numbers --line-range=:200 {}') || return
    nvim "$file"
  }

  ft() {
    local choice session

    choice=$(tmux list-sessions -F '#{session_name}	#{session_windows} windows	#{session_path}' 2>/dev/null | \
      fzf --delimiter=$'\t' --with-nth=1,2,3 --prompt='tmux sessions> ') || return

    session=${choice%%$'\t'*}
    [[ -n "$session" ]] || return

    if [[ -n "$TMUX" ]]; then
      tmux switch-client -t "$session"
    else
      tmux attach-session -t "$session"
    fi
  }

  fcd() {
    local dir
    dir=$(printf "%s\n" .. "$(fd ${=FZF_FD_COMMON_OPTS} --type d .)" | fzf --scheme=path --preview='eza --tree --level=1 --color=always {}') || return
    builtin cd -- "$dir"
  }

fi

########################
# KEYBINDINGS
########################

if [[ -o interactive ]]; then
  bindkey -e

  tmux-popup-close-widget() {
    [[ -n "$TMUX" ]] || return

    zle -I
    tmux display-popup -C >/dev/null 2>&1
    zle reset-prompt
  }

  zle -N tmux-popup-close-widget
  bindkey '^[t' tmux-popup-close-widget
fi

########################
# ENV (CUDA + RUST)
########################

export CUDA_HOME=/usr/local/cuda-13.2
[ -d "$CUDA_HOME/bin" ] && export PATH="$CUDA_HOME/bin:$PATH"
[ -d "$CUDA_HOME/lib64" ] && export LD_LIBRARY_PATH="$CUDA_HOME/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

[ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"

########################
# OPENCODE
########################

[ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"


########################
# YAZI
########################

function yazi() {
  local tmp cwd
  tmp="$(mktemp -t yazi-cwd.XXXXXX)"
  command yazi --cwd-file="$tmp" "$@"
  if cwd="$(command cat "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

alias y=yazi
alias yy=yazi

########################
# INPUT METHOD (VIETNAMESE)
########################

export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx

########################
# SETTINGS
########################

DISABLE_AUTO_UPDATE="true"

export BAT_THEME="Zenbones"

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6e6a86"

# fnm
FNM_PATH="/home/muggle/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --shell zsh)"
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH="$HOME/.config/emacs/bin:$PATH"

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

export PATH=$PATH:$HOME/.local/opt/go/bin
export PATH=$PATH:$HOME/go/bin
export PATH=$HOME/.npm-global/bin:$PATH
export PATH="$HOME/.cargo/bin:$PATH"


# Added by Antigravity CLI installer
export PATH="/home/muggle/.local/bin:$PATH"
