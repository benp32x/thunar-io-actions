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

# bash properties.sh <file path, to list of files/folders>

# Supports:
# 7z
# zip
# rar4
# tar
# tar.gz
# tar.bz2
# tar.xz

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
input=$1

total_bytes=0
total_files=0
total_folders=0
total_links=0

# item details
item_type=''
selected=''

# timestamps
modified_date='n/a'
accessed_date='n/a'

# permissions
chmod_val=''
permissions='n/a'
pt=''
pu=''
pg=''
po=''
exe_status=''

# packages
is_file_pkg=''
pkg_info=''
pkg_size_unpacked=''
pkg_size_packed=''
pkg_contents=''
pkg_ratio=''

# -----------------------------------------------------------------------------
# FUNCTIONS:
# -----------------------------------------------------------------------------

function sizeof() {
	local arg1=$1

	du -sh "$arg1" | sed -r 's/([^\t]+).*?/\1/g;'
}

# B to MiB Conversion Formula :
# 
#   Mebibyte = Byte x (8) / (8x1024x1024)
#   or
#   Mebibyte = Byte x 0.00000095367431640625
# 
# Bash does not handle floats, only integers. The following does not work:
#   size_mib=$(expr $size_b \* 0.00000095367431640625)
# so we use awk instead:
#   size_mib=$(awk "BEGIN {print $arg1 * 0.00000095367431640625}")

# How to add comma's at the thousands mark:
# echo $sizeof_bytes | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'
# or
# $(printf "%'.f\n" $sizeof_bytes)
# or also show decimal points (2)
# $(printf "%'.2f\n" $sizeof_bytes)

function sizeof_bytes() {
	local arg1=$1

	du -sb "$arg1" | sed -r 's/(^[0-9]+).*?/\1/g'
}

function sizeof_kibibytes() {
	local arg1=$1 # bytes
	local arg2=$2 # decimals (0|1|2)

	local size_kib=$(awk "BEGIN {print $arg1 * 0.0009765625}")
	local size_kib_rnd=$(printf "%.${arg2}f\n" $size_kib)

	echo "$size_kib_rnd"
}

function sizeof_mebibytes() {
	local arg1=$1 # bytes
	local arg2=$2 # decimals (0|1|2)

	local size_mib=$(awk "BEGIN {print $arg1 * 0.00000095367431640625}")
	local size_mib_rnd=$(printf "%.${arg2}f\n" $size_mib)

	echo "$size_mib_rnd"
}

function sizeof_gibibytes() {
	local arg1=$1 # bytes
	local arg2=$2 # decimals (0|1|2)

	local size_gib=$(awk "BEGIN {print $arg1 * 0.000000000931322574615478515625}")
	local size_gib_rnd=$(printf "%.${arg2}f\n" $size_gib)

	echo "$size_gib_rnd"
}

# creates a percentage based "percent bar"
function pbar() {
	local arg1=$1 # column length of percent bar
	local arg2=$2 # incoming percent value

	# bar (part1): what is arg2% of arg1, as a whole number
	local percent1=$(awk 'BEGIN {printf "%.0f", (('"$arg2"'/100)*'"$arg1"')}')

	# bar (part2): subtract arg2% of arg1, from itself
	local percent2=$(expr "$arg1" - "$percent1")

	# for rendering empty space
	local blank=''

	echo -e '\e[1;37;46m'"$(pad_stuff ${#blank} $percent1)"'\e[0m''\e[1;37;44m'"$(pad_stuff ${#blank} $percent2)"'\e[0m'
}

# -----------------------------------------------------------------------------
# BUILD DATA:
# -----------------------------------------------------------------------------

ct_tmp_length=$(cat "$input" | wc -l)

while IFS= read -r line; do

	# ----------------------------------------
	# SELECTION INFO:
	# ----------------------------------------

	# Builds:
	# > Selected
	# > Type

	if [ "$ct_tmp_length" == 1 ]
	then
		# item details
		if [ -f "$line" ]
		then
			item_type='File'
			file_type=$(
			file "$line" | \
			sed -r '
				s/[^:]+: (.+)/\1/g; 
				s/, compression method=\S+//g; 
				s/, ([^,:]+: [^,]+)/\n                \1/g; 
				s/, /\n                /g;
			')
		elif [ -d "$line" ]
		then
			item_type='Folder'
		fi
		selected="$line"
	else
		# item details
		item_type='Multiple Types'
		selected="$ct_tmp_length Items"
	fi

	# ----------------------------------------
	# PACKAGE INFO:
	# ----------------------------------------

	# extra information for 7z/zip/rar
	# Note: these archive formats provide the most amount of additional information
	#       other formats such as tar.gz make it harder to parse detailed info because the .gz file is inside a .tar file
	if [ "$ct_tmp_length" == 1 ] && \
	   [ -f "$line" ] && \
	   [[ "$line" =~ \.(7z|7z\.001|zip|rar|part1\.rar|part01\.rar|part001\.rar|tar|tar\.gz|tar\.bz2|tar\.xz)$ ]]
	then
		is_file_pkg='YES'
		pkg_info=$(7z l "$line")
		pkg_type=$(echo "$pkg_info" | grep -v "Type = Split" | grep "Type = " | sed -r 's/Type = (.+)/\1/g;')

		# needed to get file/folder totals for tar.gz/tar.bzip2/tar.xz:
		if   [ "$pkg_type" == 'gzip' ];  then pkg_info_tar=$(tar -ztvf "$line")
		elif [ "$pkg_type" == 'bzip2' ]; then pkg_info_tar=$(tar -jtvf "$line")
		elif [ "$pkg_type" == 'xz' ];    then pkg_info_tar=$(tar -Jtvf "$line")
		fi

		# core dataset across formats:
		if [ "$pkg_type" == '7z' ] || \
		   [ "$pkg_type" == 'zip' ] || \
		   [ "$pkg_type" == 'Rar' ] || \
		   [ "$pkg_type" == 'tar' ] || \
		   [ "$pkg_type" == 'gzip' ] || \
		   [ "$pkg_type" == 'bzip2' ] || \
		   [ "$pkg_type" == 'xz' ]
		then
			#grep "[0-9]\+\s\+[0-9]\+\s\+[0-9]\+ files"
			pkg_end_total=$(
				echo "$pkg_info" | \
				grep "[0-9]\+\s\+[0-9]\+ files" | \
				sort -u | \
				sed -r 's/[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\s+//g; s/^\s+//g'
			)

			if [ "$pkg_type" == 'gzip' ] || \
			   [ "$pkg_type" == 'bzip2' ] || \
			   [ "$pkg_type" == 'xz' ]
			then
				pkg_size_unpacked=$(echo "$pkg_info_tar" | awk '{s+=$3} END {print (s)}')
				pkg_contents_f=$(echo "$pkg_info_tar" | grep "^\-.\+" | wc -l)
				pkg_contents_d=$(echo "$pkg_info_tar" | grep "^\d.\+" | wc -l)
				pkg_contents_l=$(echo "$pkg_info_tar" | grep "^\l.\+" | wc -l)
				pkg_contents="$pkg_contents_f"' files, '"$pkg_contents_d"' folders, '"$pkg_contents_l"' links'
			else
				pkg_size_unpacked=$(echo "$pkg_end_total" | sed -r 's/([0-9]+)\s+[0-9]+\s+[0-9]+ files.*/\1/g;')
				pkg_contents=$(echo "$pkg_end_total" | sed -r 's/[0-9]+\s+[0-9]+\s+([0-9]+ files.*)/\1/g;')
			fi
			pkg_size_packed=$(echo "$pkg_end_total" | sed -r 's/([0-9]+\s+)?([0-9]+)\s+[0-9]+ files.*/\2/g;')

			pkg_size_physical=$(echo "$pkg_info" | grep "^Physical Size = " | sed -r 's/Physical Size = ([0-9]+)/\1/g;')

			if [ "$pkg_type" == 'Rar' ]
			then
				pkg_vol_status=$(echo "$pkg_info" | grep "^Multivolume = " | sed -r 's/Multivolume = ([+-])/\1/g;')
				pkg_vol_index=$(echo "$pkg_info" | grep "^Volume Index = " | sed -r 's/Volume Index = ([0-9]+)/\1/g;')

				# Note: not currently in use:
				#pkg_vol_total=$(echo "$pkg_info" | grep "^Volumes = " | sed -r 's/Volumes = ([0-9]+)/\1/g;')
				#if [ "$pkg_vol_status" == '+' ]
				#then
				#	pkg_size_physical_total=$(echo "$pkg_info" | grep "Total Physical Size = " | sed -r 's/Total Physical Size = ([0-9]+)/\1/g;')
				#fi
				#pkg_characteristics=$(echo "$pkg_info" | grep "^Characteristics = " | sed -r 's/Characteristics = ([0-9]+)/\1/g;')
			fi

			pkg_ratio=$(awk 'BEGIN { printf "%.2f", ('"$pkg_size_packed"'/'"$pkg_size_unpacked"'*100) }')
		fi

		if [ "$pkg_type" == '7z' ] || [ "$pkg_type" == 'xz' ]
		then
			pkg_method=$(echo "$pkg_info" | grep "Method = " | sed -r 's/Method = (.+)/\1/g;')
		fi

		if [ "$pkg_type" == '7z' ] || [ "$pkg_type" == 'Rar' ]
		then
			pkg_solid=$(echo "$pkg_info" | grep "Solid = " | sed -r 's/Solid = ([+-])/\1/g;')
		fi
	fi

	# ----------------------------------------
	# FILE/FOLDER INFO:
	# ----------------------------------------

	# Builds:
	# > Modified
	# > Accessed
	# > Permissions

	if [ "$ct_tmp_length" == 1 ]
	then
		# timestamps
		modified_date=$(stat -c '%Y' "$line" | awk '{print strftime("%m/%d/%Y, %r", $1)}')
		#accessed_date=$(stat -c '%X' "$line" | awk '{print strftime("%m/%d/%Y, %r", $1)}')

		# permissions
		chmod_val=$(stat --format '%a' "$line")
		permissions=$(stat --format '%A' "$line")
		pt=$(echo "$permissions" | sed -r 's/([-d])[-rwx]{3}[-rwx]{3}[-rwx]{3}/\1/g;')
		pu=$(echo "$permissions" | sed -r 's/[-d]([-rwx]{3})[-rwx]{3}[-rwx]{3}/\1/g;')
		pg=$(echo "$permissions" | sed -r 's/[-d][-rwx]{3}([-rwx]{3})[-rwx]{3}/\1/g;')
		po=$(echo "$permissions" | sed -r 's/[-d][-rwx]{3}[-rwx]{3}([-rwx]{3})/\1/g;')
		if [[ "$permissions" =~ 'x' ]]
		then exe_status='YES'
		else exe_status='NO'
		fi
	fi

	# ----------------------------------------
	# CONTENTS INFO (1):
	# ----------------------------------------

	# Builds:
	# > Size (bytes)
	# > Contains

	# totals for: bytes/files/folders/links
	if [ -f "$line" ]
	then
		total_files=$(($total_files + 1))
		total_bytes=$(($total_bytes + $(sizeof_bytes "$line")))
	elif [ -d "$line" ]
	then
		total_files=$(($total_files + $(find "$line" -type f | wc -l)))
		total_folders=$(($total_folders + $(find "$line" -type d | wc -l)))
		total_links=$(($total_links + $(find "$line" -type l | wc -l)))

		# Get the total bytes for ONLY files, and omit the byte values for folders:
		# 1.) create a NUL byte delimited list of files
		# 2.) disk usage of the NUL-terminated file names, then display a total in bytes
		# 3.) parse the total byte value
		total_bytes=$(($total_bytes + $(find "$line" -type f -print0 | du --files0-from=- -csb | tail -1 | sed -r 's/([0-9]+).+/\1/g;')))

		# Do not count the parent dir, if only a single dir is selected.
		# (this might be difficult to understand, so please read below)
		# ----------------------
		# Desired functionality:
		# ----------------------
		# Accessing properties for a single folder, we want to see the total 
		# files/folders "within" the directory.
		# 
		# The parent directory will only be counted if selecting the dir + 1 
		# or more items at the same dir level.
		# 
		# This follows the logic that your context is switching from wanting 
		# the properties of the folder to the properties of your "selection". 
		# The selection becomes the parent, and the /folder1 then becomes a 
		# child of that selection.
		# ---
		# /folder1/ selected                 = 203 folders (files/folders INSIDE /folder1)
		# ---
		# /folder1/, /file1, /file2 selected = 204 folders (files/folders INSIDE /folder1 + /folder1 itself)
		# ---
		if [ "$ct_tmp_length" == 1 ]; then total_folders=$(($total_folders - 1)); fi
	else
		:
	fi
done < "$input"

# ----------------------------------------
# CONTENTS INFO (2): calculate KiB/MiB/GiB
# ----------------------------------------

# Builds:
# > Size (KiB/MiB/GiB)

# note: parameter is only for if conditions below
total_mebibytes_d0=$(sizeof_mebibytes "$total_bytes" '0')

if (( $total_mebibytes_d0 < 1 ))
then
	total_kibibytes_d2=$(sizeof_kibibytes "$total_bytes" '2')
	total_size_h="$total_kibibytes_d2"' KiB'
elif (( $total_mebibytes_d0 < 1000 ))
then
	total_mebibytes_d2=$(sizeof_mebibytes "$total_bytes" '2')
	total_size_h="$total_mebibytes_d2"' MiB'
#	size_m="$size_mib_r"
elif (( $total_mebibytes_d0 > 999 ))
then
	total_gibibytes_d2=$(sizeof_gibibytes "$total_bytes" '2')
	total_size_h="$total_gibibytes_d2"' GiB'
fi

# -----------------------------------------------------------------------------
# RENDER:
# -----------------------------------------------------------------------------

label_banner ' Properties'

# ----------------------------------------
# SELECTION INFO:
# ----------------------------------------

echo 
echo '  Selected    : '"$selected"
if [ "$item_type" == 'File' ]
then
	echo '  Type        : '"$file_type"
else
	echo '  Type        : '"$item_type"
fi
echo '  Location    : '"$v_pwd"
echo 

# ----------------------------------------
# CONTENTS INFO:
# ----------------------------------------

echo -e '  Contains    : \e[1;33m'$(printf "%'.f\n" $total_files)' Files, '$(printf "%'.f\n" $total_folders)' Folders''\e[0m'
if [ "$total_links" == 0 ]
then
	# opting to hide 0 symlinks for now
	#echo -e '  Symlinks    : '$(printf "%'.f\n" $total_links)
	:
else
	echo -e '  Symlinks    : \e[0;36m'$(printf "%'.f\n" $total_links)'\e[0m'
fi
echo -e '  Size        : \e[1;32m'"$total_size_h"'\e[0m''\e[0;32m'' ('$(printf "%'.f\n" $total_bytes)' bytes)''\e[0m'
echo 

# if a single item is selected
if [ "$ct_tmp_length" == 1 ]
then
	# ----------------------------------------
	# FILE/FOLDER INFO:
	# ----------------------------------------

	# date / time
	echo '  Modified    : '"$modified_date"
	#echo '  Accessed    : '"$accessed_date"

	# permissions / exe
	echo 
	echo '  Permissions : '"$permissions"' / '"$chmod_val"
	echo 
	echo '                type  user  group  others '
	echo "                $pt     $pu   $pg    $po    "
	echo 
	if [ "$exe_status" == 'YES' ]
	then
		echo -e '                \e[1;36m''executable''\e[0m'
		echo 
	fi

	# ----------------------------------------
	# PACKAGE INFO:
	# ----------------------------------------

	if [ "$is_file_pkg" == 'YES' ]
	then
		label_step '  Package Information : '
		if [ "$pkg_type" == '7z' ] || \
		   [ "$pkg_type" == 'zip' ] || \
		   [ "$pkg_type" == 'Rar' ] || \
		   [ "$pkg_type" == 'tar' ] || \
		   [ "$pkg_type" == 'gzip' ] || \
		   [ "$pkg_type" == 'bzip2' ] || \
		   [ "$pkg_type" == 'xz' ]
		then
			echo 

			# package type/solid/method
			echo "   Type       :  $pkg_type"
			if [ "$pkg_type" == '7z' ] || [ "$pkg_type" == 'Rar' ]
			then
				echo "   Solid      :  $pkg_solid"
			fi
			if [ "$pkg_type" == '7z' ] || \
			   [ "$pkg_type" == 'xz' ]
			then
				echo "   Method     :  $pkg_method"
			fi
			echo 

			# package contents/ratio
			echo "   Contains   :  $pkg_contents"
			if [ "$pkg_vol_index" == 0 ] || [ ! "$pkg_vol_status" == '+' ]
			then
				echo '   Unpacked   :  '$(printf "%'.f\n" "$pkg_size_unpacked")' bytes'
				if [ "$pkg_type" == '7z' ] || [ "$pkg_type" == 'Rar' ]
				then echo '   Packed     :  '$(printf "%'.f\n" "$pkg_size_packed")' bytes (excluding headers)'
				else echo '   Packed     :  '$(printf "%'.f\n" "$pkg_size_packed")' bytes'
				fi
				echo 
				echo "   Ratio      :  $pkg_ratio"'%   '"$(pbar '50' "$pkg_ratio")"
			elif [ "$pkg_vol_index" != 0 ] && [ "$pkg_vol_status" == '+' ]
			then
				echo 
				echo '                 (Please select first volume to obtain detailed pack info)'
			fi

			# Note: not currently in use:
			#if [ "$pkg_type" == 'Rar' ] && [ "$pkg_vol_status" == '+' ]
			#then
			#	echo '   Vol Size   :  '$(printf "%'.f\n" "$pkg_size_physical")' bytes [ selected volume ]'
			#	echo '   Total Pack :  '$(printf "%'.f\n" "$pkg_size_physical_total")' bytes [ including headers ]'
			#	echo "   Vol Index  :  $pkg_vol_index"
			#fi

			echo 
		fi
	fi

fi
