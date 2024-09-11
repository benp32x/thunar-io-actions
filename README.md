# thunar-io-actions

Advanced I/O related Custom Actions for Thunar File Manager

[Thunar](https://en.wikipedia.org/wiki/Thunar) is the File Manager for the [XFCE](https://en.wikipedia.org/wiki/Xfce) Linux Desktop Environment. You can create Custom Actions from the context menu when right clicking on a folder or files.

See here for official documentation on Custom Actions:
https://docs.xfce.org/xfce/thunar/custom-actions

This repository contains the following Custom Actions:

* Copy File List
* Advanced Properties
* CRC32 to .sfv
* CRC32 to Terminal
* Check .sfv file
* Check .sfv's Recursively (in development)

### Config Notes

If the action requires a script from this repository, move the script to `~/bin` of your home directory, and set `chmod +x` to make it executable on the command line path.

For each custom action, access `Edit > Configure custom actions...` in Thunar, and add a new action with the applicable configuration.

In order for a list of items (files or folders) to be passed into many of these actions a tmp file is built containing a list of actionable files/folders. The provided parameters of `%n` and `%N` by Thunar work fine for simple commands. But here we are passing this data off to shell scripts, and we need a reliable way to deal with large file structures where the names of the items may or may not contain spaces/special characters. Maybe there is a better way to deal with this? Feel free to create an issue if you have thoughts on this.

Here is an expanded command for reference:

```shell
tmp_file=$(mktemp --tmpdir='/dev/shm')

for line in %N
do
	echo "$line" >> "$tmp_file"
done

xfce4-terminal -e 'bash -c "properties.sh '"$tmp_file"'; rm '"$tmp_file"'; bash"'
```

## 1.) Copy File List

Copies a list of folders and files from a directory "1 level" deep to the clipboard. This works when both right clicking on a folder item, and from within the window region of a folder itself. Multi-select or recursion are not implemented in this specific command.

### Configuration

Dependencies: xclip

Name: `Copy File List`  
Description: `Copies a list of folders and files from a directory`  
Command:
```shell
ls -1 --group-directories-first %f | xclip -i -selection clipboard
```

Appearance Conditions:

```
File Pattern: *
Range (min-max): <empty>
Appears if selection contains:

[#] Directories    [ ] Text Files
[ ] Audio Files    [ ] Video Files
[ ] Image Files    [ ] Other Files
```

## 2.) Advanced Properties

Thunar's Properties view was simply not cutting it for me. So I wrote `properties.sh`.

Features:

* I needed to see the total number of files in a folder structure (not "items" which is a generic term for folders AND files).
* I needed to get the size of a selection in "Kibibytes/Mebibytes/Gibibytes" (KiB/MiB/GiB). I do lots of classic video game research, and when I check the properties of files on Windows/Linux, I need the byte count to match.
* If an "individual" folder is selected, the file(s) / folder(s) count should not include this parent selected folder in the total. It should only deliver information what what is "inside" the folder. This follows the model that a user wants to know "what's inside" their selection if multiple items are selected, and wants to know "what's inside" a folder if a single folder is selected.
* Compensates for symlinks
* Displays archive information with compression ratio where possible. This is a feature I was very much used to having on Windows from WinRAR's GUI interface. It was very helpful, and I tried to replicate this data render as best I can with this script.

### Example Output

![properties](<./images/properties_sh.png>)

### Configuration

Dependencies: properties.sh

Name: `Advanced Properties`  
Description: `Actually show accurate data, with files and folders (not "items")`  
Command:
```shell
tmp_file=$(mktemp --tmpdir='/dev/shm'); for line in %N; do echo "$line" >> "$tmp_file"; done; xfce4-terminal -e 'bash -c "properties.sh '"$tmp_file"'; rm '"$tmp_file"'; bash"'
```

Appearance Conditions:

```
File Pattern: *
Range (min-max): <empty>
Appears if selection contains:

[#] Directories    [#] Text Files
[#] Audio Files    [#] Video Files
[#] Image Files    [#] Other Files
```

## 3.) CRC32 to .sfv

Creates a .sfv file for anything selected. If a directory is part of the selection, it will recurse and generate checksums for all files. Mult-select is supported.

Dependencies: actions_crc.sh, rhash

Name: `CRC32 to .sfv`  
Description: `For single file, or directory (with recursion)`  
Command:
```shell
tmp_file=$(mktemp --tmpdir='/dev/shm'); for line in %N; do echo "$line" >> "$tmp_file"; done; xfce4-terminal -e 'bash -c "actions_crc.sh -c '"$tmp_file"'; rm '"$tmp_file"'; bash"'
```

Appearance Conditions:

```
File Pattern: *
Range (min-max): <empty>
Appears if selection contains:

[#] Directories    [#] Text Files
[#] Audio Files    [#] Video Files
[#] Image Files    [#] Other Files
```

## 4.) CRC32 to Terminal

Generates CRC32 checksums, and outputs the result to a terminal. Works on Single/Multi Selected set of files.

Dependencies: actions_crc.sh, rhash

Name: `CRC32 to Terminal`  
Description: `Generete CRC32 Checksum to Terminal`  
Command:
```shell
tmp_file=$(mktemp --tmpdir='/dev/shm'); for line in %N; do echo "$line" >> "$tmp_file"; done; xfce4-terminal -e 'bash -c "actions_crc.sh -g '"$tmp_file"'; rm '"$tmp_file"'; bash"'
```

Appearance Conditions:

```
File Pattern: *
Range (min-max): <empty>
Appears if selection contains:

[ ] Directories    [#] Text Files
[#] Audio Files    [#] Video Files
[#] Image Files    [#] Other Files
```

## 5.) Check .sfv file

Checks an individually selected .sfv file

Dependencies: actions_crc.sh, rhash

Name: `Check .sfv file`  
Description: `Check a single .sfv File`  
Command:
```shell
tmp_file=$(mktemp --tmpdir='/dev/shm'); for line in %N; do echo "$line" >> "$tmp_file"; done; xfce4-terminal -e 'bash -c "actions_crc.sh -v '"$tmp_file"'; rm '"$tmp_file"'; bash"'
```

Appearance Conditions:

```
File Pattern: *
Range (min-max): <empty>
Appears if selection contains:

[#] Directories    [#] Text Files
[ ] Audio Files    [ ] Video Files
[ ] Image Files    [ ] Other Files
```

## 6.) Check .sfv's Recursively (in development)

The script for this action is still in development. The code I have works, but it needs a lot of cleanup.

The intent is to drill down recursively and check every .sfv file within a folder structure.

## A note on SFV files

Multiple actions above related to "SFV" files. SFV stands for "Simple File Verification". A .sfv file contains CRC32 checksums for each file you specify. This allows you to check the integrity of a file to make sure it has not been corrupted. I honestly don't know how anyone copies data to a USB Flash Drive, without creating a .sfv file to verify the data was actually written to the storage medium without corruption. I highly recommend using .sfv files when copying/transfering *anything* between 2 locations. Copying the data from one drive to another? to the internet? over your LAN? Create an SFV file before you copy it over, then check the SFV file after you've copied the data to its destination. Is your data important? Do this please.

## License

For these scripts I decided to go with the GPLv2, because this is the License for Thunar itself. Maybe someday some of this code can be included in Thunar by default? But only if the License is compatible. A GPLv3 License is not backwards compatible with GPLv2 code. So GPLv2 was chosen for the code in this repository.

```
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
```
