# vim:ft=zsh ts=2 sw=2 sts=2

# Init at 1 so new prompts are rendered in full
FULL_PROMPT='1';
preexec_done=1;

setopt promptsubst

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

build_prompt() {
  if [[ "${FULL_PROMPT}" -ne "1" ]]; then
    starship prompt --terminal-width="${COLUMNS}" --profile short
    return;
  fi
  starship prompt --terminal-width="${COLUMNS}"
}

prompt_starship_setup() {
  unsetopt XTRACE KSH_ARRAYS
  prompt_opts=(cr percent sp subst)

  add-zsh-hook precmd precmd_track
  add-zsh-hook preexec preexec_track

  PROMPT='$(build_prompt)'
  PROMPT2="$(starship prompt --continuation)"
}

prompt_starship_setup "$@"
