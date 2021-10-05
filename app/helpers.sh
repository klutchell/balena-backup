#!/usr/bin/env bash

sanitize () {
    echo "${1//[^[:alnum:]_-]/_}"
}

# https://github.com/Jeff-Russ/bash-boolean-helpers
truthy () {
	command -v "$*" >/dev/null 2>&1 || { 
		if   [ -z "$*" ];      then return 1;
		elif [ "$*" = false ]; then return 1;
		elif [ "$*" = 0 ];     then return 1;
		else return 0;
		fi
	}
	typeset cmnd="$*"
	typeset ret_code
	eval $cmnd >/dev/null 2>&1
	ret_code=$?
	return $ret_code
}
