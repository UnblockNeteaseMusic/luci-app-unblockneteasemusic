#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2019-2021 Tianling Shen <cnsztl@immortalwrt.org>

NAME="unblockneteasemusic"

function check_core_if_already_running(){
	running_tasks="$(ps |grep "$NAME" |grep "update.sh" |grep "update_core" |grep -v "grep" |awk '{print $1}' |wc -l)"
	[ "${running_tasks}" -gt "2" ] && { echo -e "\nA task is already running." >> "/tmp/$NAME.log"; exit 2; }
}

function check_luci_if_already_running(){
	running_tasks="$(ps |grep "$NAME" |grep "update.sh" |grep "update_luci" |grep -v "grep" |awk '{print $1}' |wc -l)"
	[ "${running_tasks}" -gt "2" ] && { echo -e "\nA task is already running." >> "/tmp/$NAME.log"; exit 2; }
}

function clean_log(){
	echo "" > "/tmp/$NAME.log"
}

function check_core_latest_version(){
	core_latest_ver="$(uclient-fetch -q -O- 'https://api.github.com/repos/1715173329/UnblockNeteaseMusic/commits/enhanced' | jsonfilter -e '@.sha')"
	[ -z "${core_latest_ver}" ] && { echo -e "\nFailed to check latest core version, please try again later." >> "/tmp/$NAME.log"; exit 1; }
	if [ ! -e "/usr/share/$NAME/core_local_ver" ]; then
		clean_log
		echo -e "Local version: NOT FOUND, cloud version: ${core_latest_ver}." >> "/tmp/$NAME.log"
		update_core
	else
		if [ "$(cat /usr/share/$NAME/core_local_ver)" != "${core_latest_ver}" ]; then
			clean_log
			echo -e "Local core version: $(cat /usr/share/$NAME/core_local_ver 2>"/dev/null"), cloud core version: ${core_latest_ver}." >> "/tmp/$NAME.log"
			update_core
		else
			echo -e "\nLocal core version: $(cat /usr/share/$NAME/core_local_ver 2>"/dev/null"), cloud core version: ${core_latest_ver}." >> "/tmp/$NAME.log"
			echo -e "You're already using the latest core version." >> "/tmp/$NAME.log"
			exit 3
		fi
	fi
}

function update_core(){
	echo -e "Updating core..." >> "/tmp/$NAME.log"

	mkdir -p "/usr/share/$NAME/core" > "/dev/null" 2>&1
	rm -rf /usr/share/$NAME/core/* > "/dev/null" 2>&1

	uclient-fetch -q "https://codeload.github.com/1715173329/UnblockNeteaseMusic/tar.gz/${core_latest_ver}" -O "/usr/share/$NAME/core/core.tar.gz" > "/dev/null" 2>&1
	tar -zxf "/usr/share/$NAME/core/core.tar.gz" -C "/usr/share/$NAME/core/" > "/dev/null" 2>&1
	mv "/usr/share/$NAME/core/UnblockNeteaseMusic-${core_latest_ver}"/* "/usr/share/$NAME/core/"
	rm -rf "/usr/share/$NAME/core/core.tar.gz" "/usr/share/$NAME/core/UnblockNeteaseMusic-${core_latest_ver}" > "/dev/null" 2>&1

	if [ ! -e "/usr/share/$NAME/core/app.js" ]; then
		echo -e "Failed to download core." >> "/tmp/$NAME.log"
		exit 1
	else
		[ "${update_core_from_luci}" == "y" ] && touch "/usr/share/$NAME/update_core_successfully"
		echo -e "${core_latest_ver}" > "/usr/share/$NAME/core_local_ver"
		[ "${non_restart}" != "y" ] && /etc/init.d/$NAME restart
	fi

	echo -e "Succeeded in updating core." > "/tmp/$NAME.log"
	echo -e "Current core version: ${core_latest_ver}.\n" >> "/tmp/$NAME.log"
}

case "$1" in
	"update_core")
		check_core_if_already_running
		check_core_latest_version
		;;
	"update_core_non_restart")
		non_restart="y"
		check_core_if_already_running
		check_core_latest_version
		;;
	"update_core_from_luci")
		update_core_from_luci="y"
		check_core_if_already_running
		check_core_latest_version
		;;
	*)
		echo -e "Usage: ./update.sh {update_luci|update_core}"
		;;
esac
