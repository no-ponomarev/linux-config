# ~/.bashrc — interactive bash configuration

# ─────────────────────────────────────────────────────────────────────────────
# Proxy — set before the interactive check so non-interactive shells (e.g.
# `ssh host 'git pull'`, scripts run over ssh) get it too. On machines that must
# not use it: `unset http_proxy https_proxy no_proxy` in ~/.bashrc.local.
# ─────────────────────────────────────────────────────────────────────────────
export http_proxy=http://proxy-dmz.intel.com:912
export https_proxy=http://proxy-dmz.intel.com:912
export no_proxy="127.0.0.1,localhost,intel.com"

# If not running interactively, don't do anything
case $- in
*i*) ;;
*) return ;;
esac

# Remote machines may lack terminfo for the local terminal (e.g. tmux-256color
# from local tmux) -> broken nvim/less/backspace. Fall back to a safe one.
if ! infocmp "$TERM" >/dev/null 2>&1; then
  export TERM=xterm-256color
fi

# Running under WSL? Gate Windows-only bits on this.
IS_WSL=
grep -qi microsoft /proc/version 2>/dev/null && IS_WSL=1

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────
# Prepend to PATH only if the dir exists and isn't already there
# (prevents PATH growing every time you open a nested shell / tmux pane).
path_prepend() {
  [ -d "$1" ] || return
  case ":$PATH:" in
  *":$1:"*) ;;
  *) PATH="$1:$PATH" ;;
  esac
}
__have() { command -v "$1" >/dev/null 2>&1; }

# ─────────────────────────────────────────────────────────────────────────────
# PATH / development tools
# ─────────────────────────────────────────────────────────────────────────────
path_prepend "$HOME/bin/nvim"
path_prepend "$HOME/bin/ripgrep"
path_prepend "$HOME/bin/fd"
path_prepend "$HOME/bin/bat"
path_prepend "$HOME/bin/eza"
path_prepend "$HOME/bin/tree-sitter"
path_prepend "$HOME/.local/bin" # Claude Code, pipx, etc.
export PATH

if __have nvim; then
  export EDITOR=nvim VISUAL=nvim
  alias vim='nvim' vi='nvim'
fi

# ─────────────────────────────────────────────────────────────────────────────
# History
# ─────────────────────────────────────────────────────────────────────────────
HISTCONTROL=ignoreboth:erasedups # no dups, no lines starting with space
HISTSIZE=50000
HISTFILESIZE=100000
HISTTIMEFORMAT='%F %T  '        # timestamps in `history`
HISTIGNORE='ls:ll:la:l:cd:pwd:exit:clear:history'
shopt -s histappend cmdhist

# ─────────────────────────────────────────────────────────────────────────────
# Shell behaviour
# ─────────────────────────────────────────────────────────────────────────────
shopt -s checkwinsize # update LINES/COLUMNS after each command
shopt -s globstar     # ** matches recursively
shopt -s autocd       # type a directory name to cd into it
shopt -s cdspell dirspell # fix minor typos in cd / completion
shopt -s checkjobs    # warn about running jobs on exit
shopt -s no_empty_cmd_completion

# Readline: nicer, colourful completion
bind 'set colored-stats on'              # colour completions like ls
bind 'set colored-completion-prefix on'  # highlight the typed prefix
bind 'set completion-ignore-case on'
bind 'set completion-map-case on'        # treat - and _ as equal
bind 'set show-all-if-ambiguous on'      # list on first Tab
bind 'set mark-symlinked-directories on'
bind 'set visible-stats on'
# Up/Down search history for what you've already typed
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
export LESS='-R -F -i -M' # colours, quit if one screen, smart-case search

# ─────────────────────────────────────────────────────────────────────────────
# Colours
# ─────────────────────────────────────────────────────────────────────────────
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
export GREP_COLORS='mt=1;38;5;208:fn=38;5;39:ln=38;5;71:se=38;5;244'

# ls: eza (icons, colours) when available, GNU ls otherwise.
# GNU-only flags (e.g. `ls -ltr`) need the real one: \ls or command ls.
if __have eza; then
  # Icons need a Nerd Font; VS Code's terminal usually doesn't have one
  __EZA_ICONS=auto
  [ "$TERM_PROGRAM" = vscode ] && __EZA_ICONS=never
  # Always pass a path: without one, eza reads file names from stdin when stdin
  # isn't a terminal (pipes, Claude Code/VS Code tool shells) -> empty or hangs.
  # Options must use the --opt=value form.
  # Drop any system/earlier `ls` alias (SUSE defines one). `function ls` syntax,
  # because `ls()` would be alias-expanded while this block is parsed.
  unalias ls 2>/dev/null
  function ls {
    local a
    for a in "$@"; do
      case $a in -*) ;; *) command eza --group-directories-first --icons="$__EZA_ICONS" "$@"; return ;; esac
    done
    command eza --group-directories-first --icons="$__EZA_ICONS" "$@" .
  }
  alias ll='ls -la'                 # long, incl. dotfiles
  alias la='ls -a'
  alias l='ls'
  alias lt='ls -la --sort=modified' # sorted by time, newest last
  alias tree="ls --tree --level=2 --ignore-glob='.git|build|__pycache__|node_modules'"
else
  unset -f ls 2>/dev/null
  alias ls='ls --color=auto --group-directories-first'
  alias ll='ls -alhF'
  alias la='ls -A'
  alias l='ls -CF'
  alias lt='ls -alhFtr'            # sorted by time, newest last
fi
alias grep='grep --color=auto'
alias fgrep='grep -F --color=auto'
alias egrep='grep -E --color=auto'
alias diff='diff --color=auto'
alias ip='ip --color=auto'

# bat: syntax-highlighted cat, and coloured man pages
if __have bat; then
  export BAT_THEME="${BAT_THEME:-TwoDark}"
  alias cat='bat --paging=never --style=plain' # behaves like cat in pipes
  alias bcat='bat'                             # full view: line numbers, git
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  export MANROFFOPT='-c'
else
  # Fallback: coloured man pages through less
  export LESS_TERMCAP_md=$'\e[1;36m' LESS_TERMCAP_me=$'\e[0m'
  export LESS_TERMCAP_us=$'\e[4;32m' LESS_TERMCAP_ue=$'\e[0m'
  export LESS_TERMCAP_so=$'\e[1;30;43m' LESS_TERMCAP_se=$'\e[0m'
fi

# ─────────────────────────────────────────────────────────────────────────────
# Aliases & small functions
# ─────────────────────────────────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'
alias md='mkdir -p'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias path='tr ":" "\n" <<<"$PATH"'
alias reload='source ~/.bashrc && echo "bashrc reloaded"'

# git shortcuts
alias gs='git status -sb'
alias gd='git diff'
alias gl='git log --graph --pretty=format:"%C(yellow)%h%Creset %C(blue)%ad%Creset %s%C(auto)%d %C(dim)— %an%Creset" --date=short'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

mkcd() { mkdir -p -- "$1" && cd -- "$1"; }

# extract <archive> — unpack almost anything
extract() {
  [ -f "$1" ] || { echo "extract: '$1' is not a file" >&2; return 1; }
  case "$1" in
  *.tar.bz2 | *.tbz2) tar xjf "$1" ;;
  *.tar.gz | *.tgz) tar xzf "$1" ;;
  *.tar.xz | *.txz) tar xJf "$1" ;;
  *.tar.zst) tar --zstd -xf "$1" ;;
  *.tar) tar xf "$1" ;;
  *.bz2) bunzip2 "$1" ;;
  *.gz) gunzip "$1" ;;
  *.xz) unxz "$1" ;;
  *.zip) unzip "$1" ;;
  *.7z) 7z x "$1" ;;
  *) echo "extract: don't know how to extract '$1'" >&2; return 1 ;;
  esac
}

[ -f ~/.bash_aliases ] && . ~/.bash_aliases

# ─────────────────────────────────────────────────────────────────────────────
# Completion
# ─────────────────────────────────────────────────────────────────────────────
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# fzf — fuzzy finder (Ctrl-R history, Ctrl-T files, Alt-C cd)
# ─────────────────────────────────────────────────────────────────────────────
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
if __have fzf; then
  export FZF_DEFAULT_OPTS="--height 50% --layout=reverse --border=rounded --info=inline
    --color=fg:#c0caf5,bg:-1,hl:#ff9e64,fg+:#ffffff,bg+:#283457,hl+:#ff9e64
    --color=info:#7aa2f7,prompt:#7dcfff,pointer:#bb9af7,marker:#9ece6a,spinner:#bb9af7,header:#565f89,border:#3b4261"
  if __have fd; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi
  __have bat && export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:300 {}'"
  export FZF_ALT_C_OPTS="--preview 'ls -A --color=always {} | head -100'"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Prompt
#   ╭─ user@host  ~/some/dir  ⎇ main  (conda-env)
#   ╰─❯
# ─────────────────────────────────────────────────────────────────────────────
# git branch name via the git-prompt script shipped with git
for __f in /usr/lib/git-core/git-sh-prompt \
  /usr/share/git-core/contrib/completion/git-prompt.sh \
  /usr/share/bash-completion/completions/git-prompt.sh \
  /usr/share/git/completion/git-prompt.sh; do
  [ -f "$__f" ] && { . "$__f"; break; }
done
unset __f

# Conda / venv: we draw the env name ourselves, so stop them editing PS1
export CONDA_CHANGEPS1=false
export VIRTUAL_ENV_DISABLE_PROMPT=1

# Per-cluster host colour: the laptop (WSL) stays blue; every other machine gets
# a stable colour from its name with node numbers stripped, so all nodes of a
# cluster match (aurora-uan-0012 / aurora-uan-0013 -> "aurora-uan", bmg16 -> "bmg").
# Override per machine in ~/.bashrc.local: PROMPT_HOST_COLOR=208
__host_colour() {
  [ -n "$PROMPT_HOST_COLOR" ] && { echo "$PROMPT_HOST_COLOR"; return; }
  [ -n "$IS_WSL" ] && { echo 75; return; }
  # 256-colour palette, readable on dark backgrounds, distinct from the
  # user (114), dir (39), git (213) and env (179) colours
  local palette=(208 141 80 203 221 147 43 216 99 167 117 186)
  local name=${HOSTNAME%%.*}
  name=$(sed -E 's/[-_.]*[0-9]+$//' <<<"$name")
  local sum
  sum=$(printf %s "${name:-$HOSTNAME}" | cksum)
  echo "${palette[${sum%% *} % ${#palette[@]}]}"
}
__PROMPT_HOST_COLOUR=$(__host_colour)

__build_prompt() {
  history -a # write history immediately (shared across terminals)

  # 256-colour palette; \[ \] tell readline these are zero-width
  local r='\[\e[0m\]' dim='\[\e[38;5;240m\]' bold='\[\e[1m\]'
  local c_user='\[\e[38;5;114m\]' c_host='\[\e[38;5;'${__PROMPT_HOST_COLOUR}'m\]'
  local c_dir='\[\e[38;5;39m\]' c_git='\[\e[38;5;213m\]'
  local c_env='\[\e[38;5;179m\]' c_arrow='\[\e[38;5;114m\]'
  [ "$EUID" -eq 0 ] && c_user='\[\e[1;38;5;196m\]' # root in red

  local line="${dim}╭─${r} "
  [ -n "$debian_chroot" ] && line+="${dim}(${debian_chroot})${r} "
  line+="${c_user}\u${dim}@${c_host}\h${r}  ${bold}${c_dir}\w${r}"

  if declare -F __git_ps1 >/dev/null; then
    local git
    git=$(__git_ps1 '%s')
    [ -n "$git" ] && line+="  ${c_git}⎇ ${git}${r}"
  fi

  local env="${CONDA_DEFAULT_ENV}"
  [ -n "$VIRTUAL_ENV" ] && env="${VIRTUAL_ENV##*/}"
  [ -n "$env" ] && line+="  ${c_env}(${env})${r}"

  # Terminal / tmux window title: user@host: dir
  local title='\[\e]0;\u@\h: \w\a\]'

  PS1="${title}\n${line}\n${dim}╰─${c_arrow}❯${r} "
}
PROMPT_COMMAND="__build_prompt${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# ─────────────────────────────────────────────────────────────────────────────
# AI / tokens
# ─────────────────────────────────────────────────────────────────────────────
# Secrets live in ~/.bashrc.secrets (chmod 600), not in this file, so .bashrc
# can be copied/shared safely (private tokens, exported as env variables).
[ -r "$HOME/.bashrc.secrets" ] && . "$HOME/.bashrc.secrets"

# Github token
# gh CLI: reuse the github.com token already in ~/.netrc (gh does not read netrc
# itself). Kept out of this file so the secret lives in one place.
if [ -r "$HOME/.netrc" ]; then
    GH_TOKEN="$(awk 'BEGIN{RS="[ \t\r\n]+"} {t[++n]=$0}
        END{for(i=1;i<=n;i++) if(t[i]=="machine" && t[i+1]=="github.com")
                for(j=i+2;j<=n;j++){ if(t[j]=="machine") break
                                     if(t[j]=="password"){print t[j+1]; exit} }}' "$HOME/.netrc" 2>/dev/null)"
    [ -n "$GH_TOKEN" ] && export GH_TOKEN || unset GH_TOKEN
fi

# Machine-local overrides (not tracked anywhere)
[ -f ~/.bashrc.local ] && . ~/.bashrc.local

# conda: load the `conda` command but don't activate (base) at startup.
# Use `conda activate <env>` when you need one.
export CONDA_AUTO_ACTIVATE=false

if [ -x "$HOME/bin/miniforge/bin/conda" ]; then
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$("$HOME/bin/miniforge/bin/conda" 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "$HOME/bin/miniforge/etc/profile.d/conda.sh" ]; then
        . "$HOME/bin/miniforge/etc/profile.d/conda.sh"
    else
        export PATH="$HOME/bin/miniforge/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
fi
