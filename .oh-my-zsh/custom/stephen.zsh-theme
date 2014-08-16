# Code
local ret_status="%(?:%{$fg_bold[green]%}%n:%{$fg_bold[red]%}%? %{$fg_bold[green]%}%n%s)"
PROMPT='${ret_status}%{$fg_bold[green]%}%p %{$fg_bold[blue]%}%c %{$fg_bold[blue]%}$(git_prompt_info)%{$reset_color%}$ '

ZSH_THEME_GIT_PROMPT_PREFIX="git:(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}) %{$fg[yellow]%}✗ %{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%}) "
