zstyle ":completion:*:commands" rehash 1
autoload -Uz colors && colors
alias python="python3"
source $(brew --prefix)/opt/zsh-git-prompt/zshrc.sh
PROMPT="%F{green}miutaku%f@%F{cyan}M4-MBP14%f%F{blue}($(hostname))%f:%~"$'\n'"%F{yellow}%# %f"
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
  source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  autoload -Uz compinit && compinit
fi

git_prompt() {
  if [ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" = true ]; then
    PROMPT="${PROMPT} $(git_super_status)"$'\n'"%# "
  fi
}

add_newline() {
  if [[ -z $PS1_NEWLINE_LOGIN ]]; then
    PS1_NEWLINE_LOGIN=true
  else
    printf '\n'
  fi
}
precmd() {
  git_prompt
  add_newline
}

export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# Python
eval "$(pyenv init -)"
