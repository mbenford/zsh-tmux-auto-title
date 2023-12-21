# zsh-tmux-auto-title plugin
# version: 1.0.0
# https://github.com/mbenford/zsh-tmux-auto-title

! (( $+commands[tmux] )) && { >&2 echo "zsh-tmux-auto-title: tmux not found. Please install tmux before using this plugin."; return 1 }

: ${ZSH_TMUX_AUTO_TITLE_TARGET:=pane}
: ${ZSH_TMUX_AUTO_TITLE_SHORT:=false}
: ${ZSH_TMUX_AUTO_TITLE_SHORT_EXCLUDE:=}
: ${ZSH_TMUX_AUTO_TITLE_EXPAND_ALIASES:=true}
: ${ZSH_TMUX_AUTO_TITLE_IDLE_TEXT:=%shell}
: ${ZSH_TMUX_AUTO_TITLE_IDLE_DELAY:=1}
: ${ZSH_TMUX_AUTO_TITLE_PREFIX:=}
: ${ZSH_TMUX_AUTO_TITLE_ALWAYS_SHOW_IDLE_TEXT:=false}

typeset -g ZSH_TMUX_AUTO_TITLE_LAST
typeset -g ZSH_TMUX_AUTO_TITLE_PARSED_IDLE_TEXT

_zsh_tmux_auto_title_set_title() {
	case $ZSH_TMUX_AUTO_TITLE_TARGET in
		window) printf "\ek$1\e\\" ;;
		pane)   printf "\e]2;$1\e\\" ;;
	esac
}

_zsh_tmux_auto_title_update_idle_text() {
	local title=$ZSH_TMUX_AUTO_TITLE_IDLE_TEXT

	case $title in
		%pwd)   title=$(print -P %~) ;;
		%shell) title=$(echo -n ${0:s/-//}) ;;
		%last)  title="!$ZSH_TMUX_AUTO_TITLE_LAST" ;;
	esac
	ZSH_TMUX_AUTO_TITLE_PARSED_IDLE_TEXT=$ZSH_TMUX_AUTO_TITLE_PREFIX$title
}

_zsh_tmux_auto_title_preexec() {
	setopt extended_glob

	local cmd=${1[(wr)^(*=*|sudo|ssh|mosh|-*)]:gs/%/%%}
	local line="${2:gs/%/%%}"

	[[ -z "$cmd" ]] && return

	if [[ "$ZSH_TMUX_AUTO_TITLE_EXPAND_ALIASES" = "true" ]]; then
		local cmd_type=$(whence -w $cmd | awk '{print $2}')
		[[ "$cmd_type" = "alias" ]] && cmd=$(whence $cmd)
	fi

	local title=$ZSH_TMUX_AUTO_TITLE_PREFIX$line
	[[ "$ZSH_TMUX_AUTO_TITLE_SHORT" = "true" ]] && 
	! [[ "$cmd" =~ "$ZSH_TMUX_AUTO_TITLE_SHORT_EXCLUDE" ]] && title=$cmd

	if [[ "$ZSH_TMUX_AUTO_TITLE_ALWAYS_SHOW_IDLE_TEXT" = "true" ]]; then
		_zsh_tmux_auto_title_update_idle_text
		title="$ZSH_TMUX_AUTO_TITLE_PARSED_IDLE_TEXT | $title"
	fi
	ZSH_TMUX_AUTO_TITLE_LAST=$title
	_zsh_tmux_auto_title_set_title $title
}

_zsh_tmux_auto_title_precmd() {
	_zsh_tmux_auto_title_update_idle_text
	if [[ "$ZSH_TMUX_AUTO_TITLE_IDLE_DELAY" = "0" ]]; then
		_zsh_tmux_auto_title_set_title $ZSH_TMUX_AUTO_TITLE_PARSED_IDLE_TEXT
	else	
		sched +$ZSH_TMUX_AUTO_TITLE_IDLE_DELAY _zsh_tmux_auto_title_set_title "$ZSH_TMUX_AUTO_TITLE_PARSED_IDLE_TEXT"
	fi
}

autoload -U add-zsh-hook
add-zsh-hook preexec _zsh_tmux_auto_title_preexec
add-zsh-hook precmd _zsh_tmux_auto_title_precmd
