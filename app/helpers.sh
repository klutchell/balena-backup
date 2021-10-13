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

request_lock () {
	if [ -f /var/run/app.lock ]
	then
		warn "It appears that another task is in progress..."
		warn "If this seems incorrect, try deleting /var/run/app.lock or restarting the container."
		exit 0
	fi
	touch /var/run/app.lock
}

release_lock () {
	rm /var/run/app.lock 2>/dev/null || true
}

rsync_rsh() {
    echo "bash -c \"ssh -o LogLevel=ERROR -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
		${1}@ssh.balena-devices.com host -s ${2} \${@:1}\""
}

exec_ssh_cmd() {
    ssh -o LogLevel=ERROR -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22 \
        "${1}@ssh.balena-devices.com" host -s "${2}" "${@:2}"
}

debug () {
	echo "[DEBUG] ${*}"
}

info () {
	echo "[INFO] ${*}"
}

warn () {
	echo "[WARN] ${*}"
}

error () {
	echo "[ERROR] ${*}"
}

fatal () {
	echo "[FATAL] ${*}"
}
