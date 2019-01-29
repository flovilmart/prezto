# vim:ft=zsh ts=2 sw=2 sts=2

CURRENT_BG='NONE'
FULL_PROMPT='0';
preexec_done=0;
preexec_track() {
  preexec_done=1;
}

precmd_track() {
  if [[ "$preexec_done" -eq "1" ]]; then
    FULL_PROMPT='1';
  else
    FULL_PROMPT='0';
  fi;
  preexec_done=0;
}
preexec_functions=(preexec_track)
precmd_functions=(precmd_track)
# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n "%{%k%F{$CURRENT_BG}%}"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment 'NONE' default "%(!.%{%F{yellow}%}.)$USER@%m"
  fi
}

prompt_kube() {
  prompt_segment 'NONE' green '☁️  '
  echo -n "$(kubectl config current-context)"
}

prompt_bzr() {
    (( $+commands[bzr] )) || return
    if (bzr status >/dev/null 2>&1); then
        status_mod=`bzr status | head -n1 | grep "modified" | wc -m`
        status_all=`bzr status | head -n1 | wc -m`
        revision=`bzr log | head -n2 | tail -n1 | sed 's/^revno: //'`
        if [[ $status_mod -gt 0 ]] ; then
            prompt_segment yellow black
            echo -n "bzr@"$revision "✚ "
        else
            if [[ $status_all -gt 0 ]] ; then
                prompt_segment yellow black
                echo -n "bzr@"$revision

            else
                prompt_segment green black
                echo -n "bzr@"$revision
            fi
        fi
    fi
}

prompt_hg() {
  (( $+commands[hg] )) || return
  local rev status
  if $(hg id >/dev/null 2>&1); then
    if $(hg prompt >/dev/null 2>&1); then
      if [[ $(hg prompt "{status|unknown}") = "?" ]]; then
        # if files are not added
        prompt_segment red white
        st='±'
      elif [[ -n $(hg prompt "{status|modified}") ]]; then
        # if any modification
        prompt_segment yellow black
        st='±'
      else
        # if working copy is clean
        prompt_segment green black
      fi
      echo -n $(hg prompt "☿ {rev}@{branch}") $st
    else
      st=""
      rev=$(hg id -n 2>/dev/null | sed 's/[^-0-9]//g')
      branch=$(hg id -b 2>/dev/null)
      if `hg st | grep -q "^\?"`; then
        prompt_segment red black
        st='±'
      elif `hg st | grep -q "^[MA]"`; then
        prompt_segment yellow black
        st='±'
      else
        prompt_segment green black
      fi
      echo -n "☿ $rev@$branch" $st
    fi
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment 'NONE' blue '%~'
}

# Virtualenv: current working virtualenv
prompt_virtualenv() {
  local virtualenv_path="$VIRTUAL_ENV"
  if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
    prompt_segment 'NONE' blue "(`basename $virtualenv_path`)"
  fi
}

prompt_newline() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n "%{%k%F{$CURRENT_BG}%}
"
  else
    echo -n "%{%k%}"
  fi

  echo -n "%{%f%}"
  CURRENT_BG=''
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  echo -n "%(?.%F{green}${1:-☻}%f.%F{red}${1:-☻}%f)"
}

prompt_date() {
  echo -n "$(date +%H:%M) "
}

prompt_indicator() {
  prompt_date
  echo -n "%{%k%F{red}%}$"
}

prompt_git() {
  echo -n " %f${git_info:+${(e)git_info[prompt]}}"
}

## Main prompt
build_prompt() {
  if [[ "${FULL_PROMPT}" -ne "1" ]]; then
    prompt_indicator
    prompt_end 
    exit 0
  fi
  prompt_status
  prompt_virtualenv
  prompt_context
  prompt_dir
  prompt_git
  [[ "${kube_prompt}" -eq "1" ]] && prompt_kube
  prompt_bzr
  prompt_hg
	prompt_newline
  prompt_indicator
  prompt_end
}

prompt_zimple_precmd() {
  # Get Git repository information.
  if (( $+functions[git-info] )); then
    git-info
  fi
}

prompt_zimple_setup() {
  unsetopt XTRACE KSH_ARRAYS
  prompt_opts=(cr percent sp subst)

  # Add hook for calling git-info before each command.
  add-zsh-hook precmd prompt_zimple_precmd

  # Set editor-info parameters.
  zstyle ':prezto:module:editor:info:completing' format '%B%F{red}...%f%b'

  # Set python-info parameters.
  zstyle ':prezto:module:python:info:virtualenv' format '%F{yellow}[%v]%f '

  # Set ruby-info parameters.
  zstyle ':prezto:module:ruby:info:version' format '%F{yellow}[%v]%f '

  # Set git-info parameters.
  zstyle ':prezto:module:git:info' verbose 'yes'
  zstyle ':prezto:module:git:info:branch' format '%F{green}%b%f'
  zstyle ':prezto:module:git:info:dirty' format '%%B%F{red} ±%f%%b'
  zstyle ':prezto:module:git:info:keys' format 'prompt' '(%b%D)'

  # Define prompts.
  PROMPT='$(build_prompt) '
}

prompt_zimple_setup "$@"

