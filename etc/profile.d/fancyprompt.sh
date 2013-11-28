#---------------------------------------------------------------------
# HOW TO USE
# 
# Copy into /etc/profile.d and check if /etc/profile sources it
#---------------------------------------------------------------------

## PS1 customizing
GREEN=$'\e[1;32m'
RED=$'\e[1;31m'
BLUE=$'\e[1;34m'
PURPLE=$'\e[1;35m'
GRAY=$'\e[1;30m'
RS=$'\e[0m'

#OK=$'\342\234\224'		# Check sign
OK='>'
#ERROR=$'\342\234\227'	# X sign
ERROR='x'

get_exit_status() {
	EXIT=$?
	if [ ${EXIT} -eq 0 ] ; then
		echo ''
	else
		echo ${RED}[${EXIT}]' '
	fi
}
get_user_color() {
	USER=$(whoami)
	if [ "${USER}" = "root" ] ; then
		echo ${RED}
	else
		echo ${GREEN}
	fi
}

# If you use double quotes, all variables will be expanded at this stage and will not be updated (thus $? is always 0)"
# With $'~'(note the dollar sign), all escape sequences EXCEPT \e will not be expanded.
# Use \[ and \] around non-printing sequences (such as color-changers) to prevent the bash display from being garbled up.
export PS1='\[$(get_exit_status)\]\[$(get_user_color)\]\u \[${RS}\]:: \[${BLUE}\]\w \[${RS}\]:: \[${PURPLE}\]\t\[${GRAY}\]\n> \[${RS}\]'
