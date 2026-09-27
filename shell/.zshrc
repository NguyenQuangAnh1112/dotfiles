################################################################################
# ENVIRONMENT & PATH CONFIGURATION
################################################################################

# Tự động loại bỏ trùng lặp trong PATH và fpath
typeset -U path PATH fpath FPATH cdpath CDPATH

path=(
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "$HOME/.npm-global/bin"
  "$HOME/.dotnet"
  "$HOME/.local/opt/go/bin"
  "$HOME/go/bin"
  "$HOME/.config/emacs/bin"
  "$HOME/.opencode/bin"
  /usr/local/cuda-13.2/bin
  $path
)

export EDITOR=nvim
export DOTNET_ROOT="$HOME/.dotnet"

# CUDA
export CUDA_HOME=/usr/local/cuda-13.2
[ -d "$CUDA_HOME/lib64" ] && export LD_LIBRARY_PATH="$CUDA_HOME/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# Vietnamese Input Method (fcitx)
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx

# Bat Theme
export BAT_THEME="Zenbones"

# fnm (Fast Node Manager)
if [ -d "$HOME/.local/share/fnm" ]; then
  path=("$HOME/.local/share/fnm" $path)
  eval "$(fnm env --shell zsh)"
fi

# envman
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

################################################################################
# OH MY ZSH
################################################################################

if [[ -d "$HOME/.oh-my-zsh" ]]; then
  export ZSH="$HOME/.oh-my-zsh"
  ZSH_THEME="robbyrussell"

  # Hiệu năng: Tắt kiểm tra cập nhật định kỳ khi mở shell
  DISABLE_AUTO_UPDATE="true"

  # Hiệu năng: Không quét untracked files trong Git để prompt phản hồi tức thì
  DISABLE_UNTRACKED_FILES_DIRTY="true"

  # Màu gợi ý autosuggestions
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6e6a86"

  plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
  source "$ZSH/oh-my-zsh.sh"
fi

################################################################################
# HISTORY & SHELL OPTIONS
################################################################################

HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

setopt appendhistory
setopt sharehistory
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_reduce_blanks

setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS

################################################################################
# INTERACTIVE FEATURES
################################################################################

if [[ -o interactive ]]; then

  # Tìm kiếm lịch sử bằng mũi tên Lên/Xuống theo tiền tố lệnh (Native, 0ms)
  autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
  zle -N up-line-or-beginning-search
  zle -N down-line-or-beginning-search
  bindkey '^[[A' up-line-or-beginning-search
  bindkey '^[[B' down-line-or-beginning-search
  bindkey -e

  # Zoxide (cd thông minh)
  eval "$(zoxide init zsh)"

  # Aliases
  alias cd="z"
  alias cat='bat --paging=never'
  alias v='nvim'
  alias 'v.'='nvim -c Oil'
  alias e="exit"
  alias cls="clear"
  alias ntm='tmux new-session -s'
  alias off="sudo systemctl poweroff"
  alias reboot="sudo systemctl reboot"
  alias vspeaker='pactl list short sinks | grep -q virtual_speaker || pactl load-module module-null-sink sink_name=virtual_speaker sink_properties=device.description=VirtualSpeaker'
  alias fetch='fastfetch'

  # fff.nvim (Fast File Finder)
  function ff() {
    if [ -n "$1" ] && [ -d "$1" ]; then
      nvim -c "lua require('fff').find_files_in_dir('$1')"
    else
      nvim -c "lua require('fff').find_files()"
    fi
  }

  function fg() {
    nvim -c "lua require('fff').live_grep()"
  }

  # Yazi
  alias y="command yazi"
  function yz() {
    local tmp cwd
    tmp="$(mktemp -t yazi-cwd.XXXXXX)"
    command yazi --cwd-file="$tmp" "$@"
    if cwd="$(command cat "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
      builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
  }

  # Antigravity & Tmux shortcuts
  alias agyp="agy-preview"
  alias agyl="agy-preview"
  alias tsb="tmux-scrollback"

  tmux-popup-close-widget() {
    [[ -n "$TMUX" ]] || return
    zle -I
    tmux display-popup -C >/dev/null 2>&1
    zle reset-prompt
  }
  zle -N tmux-popup-close-widget
  bindkey '^[t' tmux-popup-close-widget

  # FZF
  [ -f /usr/share/fzf/shell/key-bindings.zsh ] && source /usr/share/fzf/shell/key-bindings.zsh
  [ -f /usr/share/fzf/shell/completion.zsh ] && source /usr/share/fzf/shell/completion.zsh

  export FZF_FD_COMMON_OPTS='--no-ignore --hidden --follow --strip-cwd-prefix --exclude .git --exclude .cache --exclude node_modules --exclude .npm --exclude .venv --exclude __pycache__ --exclude Library --exclude Temp --exclude obj'
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
    choice=$(tmux list-sessions -F '#{session_name}	#{session_windows}	#{session_path}' 2>/dev/null | \
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

  # Fedora Update Reminder
  if command -v fedora-update-check &>/dev/null; then
    fedora-update-check
  fi

  # Tắt delay khi gõ sai lệnh của PackageKit
  unfunction command_not_found_handler 2>/dev/null || true

fi

# Tự động biên dịch ngầm ~/.zshrc sang bytecode nếu có thay đổi
if [[ -s "$HOME/.zshrc" && (! -s "$HOME/.zshrc.zwc" || "$HOME/.zshrc" -nt "$HOME/.zshrc.zwc") ]]; then
  zcompile "$HOME/.zshrc" &>/dev/null &!
fi
