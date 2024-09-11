#!/bin/bash

# Copyright (C) 2024 Ben Pekarek
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

# -----------------------------------------------------------------------------
# USAGE:
# -----------------------------------------------------------------------------

# 3 options are available:

# Create      bash actions_crc.sh -c -t 7z|zip|tar <input>
# Generate    bash actions_crc.sh -g -t 7z|zip|tar <input>
# Verify      bash actions_crc.sh -v               <input>

# -----------------------------------------------------------------------------
# FLAGS:
# -----------------------------------------------------------------------------

while getopts cgt:v name
do
	case $name in
		c)copt=1;;
		g)gopt=1;;
		t)topt=$OPTARG;;
		v)vopt=1;;
		*)echo "Invalid arg";;
	esac
done

# flag flush to make ready for real arguments
shift $(($OPTIND -1))

# -----------------------------------------------------------------------------
# GLOBAL FUNCTIONS:
# -----------------------------------------------------------------------------

# -------------------------------
# PUBLIC DOMAIN CODE - START:

# The following functions are released into the PUBLIC DOMAIN:
# 
#   pad_stuff()
#   chk_color()
#   label_*() [all label_ functions]
#   ind_*() [all ind_ functions]
# 
# These functions are used across many of my bash scripts for simple color 
# formatting. To avoid open source licensing conflicts, these functions are 
# released into the public domain. 
# 
# You have permission to use/modify the code within this specific code block.
# For the rest of the code in this project, you must adhere to the parent 
# project's open source license.

function pad_stuff() {
	local arg1=$1 # string length
	local arg2=$2 # to pad

	# pad columns
	# http://stackoverflow.com/questions/238073/how-to-add-a-progress-bar-to-a-shell-script
	for ((i=0; i < ("$arg2" - "$arg1"); i++)) {
		echo -en " ";
	}
}

# COLOR CODE: START
# these are color labels, with the option to disable the colors perminantly 
# via a nocolor mode or via the -x flag
nocolor="NO" # YES|NO

function chk_color() {
	local arg1=$1

	if [ $nocolor == "YES" ]
	then
		c_start=''
		c_end=''
	else
		c_start="$arg1"
		c_end='\e[0m'
	fi
}

function label_banner() {
	local arg1=$1;
	local arg1_pad=$(pad_stuff "${#arg1}" '80')

	chk_color '\e[1;37;104m'
	printf "$c_start"'%s'"$c_end"'\n' "$arg1$arg1_pad"
}
function label_banner_good() {
	local arg1=$1;
	local arg1_pad=$(pad_stuff "${#arg1}" '80')

	chk_color '\e[0;30;90m'
	printf "$c_start"'%s'"$c_end"'\n' "$arg1$arg1_pad"
}
function label_step()    { local arg1=$1; chk_color '\e[1;35m';    printf "$c_start"'%s'"$c_end"'\n' "$arg1"; }
function label_title()   { local arg1=$1; chk_color '\e[1;36m';    printf "$c_start"'%s'"$c_end"'\n' "$arg1"; }
function label_null()    { local arg1=$1; chk_color '\e[1;30m';    printf "$c_start"'%s'"$c_end"'\n' "$arg1"; }
function label_good()    { local arg1=$1; chk_color '\e[0;32m';    printf "$c_start"'%s'"$c_end"'\n' "$arg1"; }
function label_bad()     { local arg1=$1; chk_color '\e[0;31m';    printf "$c_start"'%s'"$c_end"'\n' "$arg1"; }
function label_success() { local arg1=$1; chk_color '\e[1;32m';    printf "$c_start"'%s'"$c_end"'\n' "$arg1"; }
function label_error()   { local arg1=$1; chk_color '\e[1;37;41m'; printf "$c_start"'%s'"$c_end"'\n' "$arg1"; }
function label_warn()    { local arg1=$1; chk_color '\e[1;33m';    printf "$c_start"'%s'"$c_end"'\n' "$arg1"; }
function label_note()    { local arg1=$1; chk_color '\e[0;33m';    printf "$c_start"'%s'"$c_end"'\n' "$arg1"; }

function ind_good()      { local arg1=$1; local arg2=$2; local arg1_pad=$(pad_stuff "${#arg1}" '2'); chk_color '\e[0;32m'; printf '[ '"$c_start$arg1$arg1_pad$c_end"' ] %s\n' "$arg2"; }
function ind_bad()       { local arg1=$1; local arg2=$2; local arg1_pad=$(pad_stuff "${#arg1}" '2'); chk_color '\e[0;31m'; printf '[ '"$c_start$arg1$arg1_pad$c_end"' ] %s\n' "$arg2"; }
function ind_title()     { local arg1=$1; local arg2=$2; local arg1_pad=$(pad_stuff "${#arg1}" '2'); chk_color '\e[1;36m'; printf '[ '"$c_start$arg1$arg1_pad$c_end"' ] %s\n' "$arg2"; }
# COLOR CODE: END

# PUBLIC DOMAIN CODE - END
# -------------------------------

# -----------------------------------------------------------------------------
# VARS:
# -----------------------------------------------------------------------------

v_pwd=$(pwd)
cdir=$(basename "$v_pwd")
log="/dev/shm/actions_crc_$(date +%s).log" # (not in use)

# Input is a tmp file containing a dump of %n or %N from Thunar Custom Actions
input=$1

# -----------------------------------------------------------------------------
# CREATE SFV:
# -----------------------------------------------------------------------------

if [ ! -z $copt ]
then
	ct_input=$(cat "$input" | wc -l)
	input_data=$(cat "$input")

	if [ "$ct_input" == 1 ] && [ -f "$input_data" ]
	then
		if [ ! -f "$f_out"'.sfv' ]
		then
			f_out=$(echo "$input_data" | sed -r 's/(.+)\.\S+/\1/g;');
			rhash -P --speed --crc32 --file-list="$input" --output="$f_out"'.sfv'
		else
			echo 'Error: SFV already exists - ('"$f_out"'.sfv'')'
		fi
	else
		if [ ! -f "$cdir"'.sfv' ]
		then
			# expand to include all files and no symlinks
			tmp_file2=$(mktemp --tmpdir='/dev/shm')

			while IFS= read -r line; do
				find "$line" -type f >> "$tmp_file2"
			done < "$input"

			rhash -P --speed --crc32 --file-list="$tmp_file2" --output="$cdir"'.sfv'

			# cleanup
			rm "$tmp_file2"
		else
			echo 'Error: SFV already exists - ('"$cdir"'.sfv'')'
		fi
	fi
fi

# -----------------------------------------------------------------------------
# GENERATE CRC32 CHECKSUM:
# -----------------------------------------------------------------------------

if [ ! -z $gopt ]
then
	while IFS= read -r line; do
		rhash --crc32 --simple --uppercase "$line"
	done < "$input"
fi

# -----------------------------------------------------------------------------
# VERIFY SFV:
# -----------------------------------------------------------------------------

if [ ! -z $vopt ]
then
	while IFS= read -r line; do
		if [[ "$line" =~ ^(.+\.sfv)$ ]]
		then
			rhash -P -c -r --crc32 "$line"
		else
			echo 'Error: Wrong file type (.sfv required)'
		fi
	done < "$input"
fi
