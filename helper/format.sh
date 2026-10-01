# Define ANSI colors and markers
_yclear="\e[0m"
_yerror="\e[31m"
_ywarn="\e[33m"
_yinfo="\e[32m"
_ydebug="\e[34m"

_ybold="\e[1m"
_yitalic="\e[3m"
_yunderline="\e[4m"
_yblink="\e[5m"
_yreset="\e[21m\e[22m\e[23m\e[24m\e[25m\e[26m\e[27m\e[28m\e[29m"

if [ -n "$CXDEVCIMODE" ]; then
	_yclear=
	_yerror=
	_ywarn=
	_yinfo=
	_ydebug=

	_ybold=
	_yitalic=
	_yunderline=
	_yblink=
	_yreset=
fi

# Indent functions for log messages
_yindent () {
	sed 's/^/       /'
}