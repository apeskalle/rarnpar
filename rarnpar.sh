#!/bin/bash
########################################################################
# Rarnpar - script to rar and par your usenet uploads
# Copyright (c) 2011-2013, Tadeus Dobrovolskij
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
########################################################################
# 2013-10-24: Fixed minor bug by cleaning up the old code; version 0.81
# 2013-10-21: Added newsmangler support; version 0.80
# 2013-10-18: GPL v2 Licence added.
# 2013-10-04: Added config file support; version 0.78
# 2013-09-04: Added -PR option; version 0.77
# 2013-08-30: .tmp suffix won't be added, when output directory was specified; version 0.76
# 2013-08-30: Added additional check for --par; version 0.75
# 2013-08-28: Small fix for --par option; version 0.74
# 2013-08-28: User is now able to add additional files to a rarset; version 0.73
# 2013-08-27: User is now able to add additional files to a parset; version 0.72
# 2013-08-26: Fixed small bug with .nfo file creation; version 0.71
# 2013-07-19: Added option to set custom names directly via script; version 0.7
# 2013-07-19: Autogenerated SFV file will use crypto-name when needed; version 0.69
# 2013-07-18: Added rarnpar header to the nfos; version 0.68
# 2013-07-17: Now script displays help if launched without options; version 0.67
# 2013-07-17: Default suffix isn't needed if prefix is specified; version 0.66
# 2013-07-15: Added option to encrypt rar with password; version 0.65
# 2013-06-17: Added exclusion list option for file mode; version 0.6
# 2013-02-28: Fixed the bug, when .nfo/.sfv files were not properly created in normal mode; version 0.52
# 2013-02-26: Fixed a critical bug, which forced crypto-mode on user; version 0.51
# 2013-01-16: Output directory option and recursive mode; SFV creation; version 0.5
# 2013-01-15: Added block count and starting dir options; Version 0.43
# 2013-01-11: Added .nfo file creation for media files; Version 0.41
# 2013-01-09: Added cryptorenaming mode; Version 0.4
# 2012-11-11: Fixed bugs with subdir mode; Version 0.32
# 2012-09-16: Added normal prerequisites check; Can now rarnpar subdirectories; Version bump to 0.3
# 2011-08-20: Initial public release; version 0.22
# TODO: remove the need of default suffix and fix the problems with a processing of files without extension

# Simple check to find out if you have installed needed tools.
type par2 > /dev/null 2>&1 || { echo "Error: par2 not found!"; exit 1; }

type rar > /dev/null 2>&1 || { echo "Error: rar not found!"; exit 1; }
type md5sum > /dev/null 2>&1 || { echo "WARNING: md5sum not found! md5 cryptorenaming won't work!"; }
type sha1sum > /dev/null 2>&1 || { echo "WARNING: sha1sum not found! sha1 cryptorenaming won't work!"; }
type sha224sum > /dev/null 2>&1 || { echo "WARNING: sha224sum not found! sha224 cryptorenaming won't work!"; }
type sha256sum > /dev/null 2>&1 || { echo "WARNING: sha256sum not found! sha256 cryptorenaming won't work!"; }
type sha384sum > /dev/null 2>&1 || { echo "WARNING: sha384sum not found! sha384 cryptorenaming won't work!"; }
type sha512sum > /dev/null 2>&1 || { echo "WARNING: sha512sum not found! sha512 cryptorenaming won't work!"; }

# Function to set variables to default values
defaults() {
	############################
	#
	# Variables
	############################
	# File name prefix
	NAME_PREFIX=
	# File name suffix
	NAME_SUFFIX=
	# Rar volume size in megabytes 
	VOLUME_SIZE=50
	# Par block size
	BLOCK_SIZE=768000
	# Par block count; unusable together with size
	BLOCK_COUNT=0
	# Par recovery %
	PAR_RECOVERY=10
	# Move new files to subdirectories or not?
	DIRECTORIES=0
	# Rar command
	RARC=
	# Par2 command
	PAR2C=
	# File which will be processed by script next
	FILE_TO_PROCESS=
	# Directory which will be processed in subdirectory mode
	DIRECTORY_TO_PROCESS=
	# FILENAME=prefix+(actual_file_name - extension)+suffix
	FILENAME=
	# Use rar names of the new type?
	OLDRAR=0
	# Rar compression level
	COMPRESSION=0
	# Uniform par file size
	UNIFORM=0
	# Subdirectory preparation mode flag
	SUBDIRECTORIES=0
	# Limit size of par2 recovery files. Can't be used with UNIFORM=1
	LIMIT=0
	# Process files larger than minimum size
	MINIMUMS=0
	# Verbosity
	VERBOSE=0
	# Crypto-renaming mode
	CRYPTMODE=0
	# Algorithm to use; sha1, sha224, sha256, sha384, sha512, md5
	ALGO=
	# Original directory name, before renaming in crypto mode
	ORIGINAL_DIR=
	# Original FILENAME, before cryptorenaming
	ORIGINAL_NAME=
	# Original file name, with extension, before renaming in crypto mode
	ORIGINAL_FILE_EXT=
	# Same as above, only without extension
	ORIGINAL_FILE=
	# File extension from ORIGINAL_FILE_EXT
	EXT=
	# Create nfo?
	NFO=0
	# Filetypes to check by mediainfo
	SUPPORTED_BY_MINFO=("mkv" "avi" "wmv" "mp4" "mov" "ogg" "ogm" "wav" "mka" "mks" "mpeg" "mpg" "vob" "mp3" "asf" "ape" "flac")
	# Starting directory; by default script runs in ./
	STARTING_DIR=
	# Output directory; by default script dumps everything in ./
	OUTPUT_DIR=
	# Recursive mode. Off by default.
	RECURSIVE=0
	# Depth string. Modified in recursive mode.
	MAXDEPTH="-maxdepth 1"
	# Create SFV?
	CREATE_SFV=0
	# Filenames to exclude
	EXCLUDE_LIST=
	# Password for rar encryption
	PASSWORD=
	# Rename to this string
	RENAME_TO=
	# Add files to parset
	ADD_TO_PAR=
	# We will be manipulating ADD_TO_PAR variable, but we wan't to have original value
	ORIGINAL_ADD_TO_PAR=
	# Add files to rarset
	ADD_TO_RAR=
	# We will be checking if the files exist(to add them to a parset)
	FILES_TO_CHECK=
	# Result of the check process will be stored in the following variable
	CHECK_RESULT=
	# File we are currently checking
	CFILE=
	# Do we need to generate a password for a user?
	RND_PASSWD=0
	# Password length
	PASSWORD_LENGTH=
	# We need to store original RARC variable to be able to generate passwords for each and every rar
	ORIGINAL_RARC=
	# Path to config file
	CONFIG=
	# Do we need to upload all the files automatically?
	UPLOAD=0
	# In case if newsmangler isn't in the PATH - user needs to specify where to find it
	PATH_TO_MANGLER=
}
# Generate .nfo header
generate_nfo_header() {
	echo "Generated using rarnpar"
	echo "To get rarnpar please visit: http://tad-do.net/rarnpar/"
	echo
}

# This function is used to check if files exist before trying to add/copy them 
check_files() {
	# We will be checking 2 directories: 1. current. 2. output
	if [ -z "$ORIGINAL_ADD_TO_PAR" ]
	then
		ORIGINAL_ADD_TO_PAR=$ADD_TO_PAR
	fi
	FILES_TO_CHECK=$ORIGINAL_ADD_TO_PAR
	CHECK_RESULT=
	for CFILE in $FILES_TO_CHECK
	do
		# if we have full path there - we won't be doing the second step
		if [[ "$CFILE" == \/* ]]
		then
			if ls $CFILE
			then
				CFILE=$(ls $CFILE)
				CHECK_RESULT="$CHECK_RESULT $CFILE"
			fi
		else
			# lets check current directory
			if ls "$STARTING_DIR"/$CFILE &> /dev/null
			then
				CFILE=$(ls "$STARTING_DIR"/$CFILE)
				CHECK_RESULT="$CHECK_RESULT $CFILE"
			# maybe user wants some file that is in output directory, like sfv
			elif ls "${OUTPUT_DIR}${FILENAME}"/$CFILE &> /dev/null
			then
				CFILE=$(ls "${OUTPUT_DIR}${FILENAME}"/$CFILE)
				CHECK_RESULT="$CHECK_RESULT $CFILE"
			fi
			# nonexisting files will be skipped
		fi
	done
	ADD_TO_PAR=$CHECK_RESULT
}

create_sfv_and_run_check() {
	# Create SFV if needed
	(( $CREATE_SFV == 1 )) && cksfv -b "${OUTPUT_DIR}${FILENAME}"/"${FILENAME}"*.r* > "${OUTPUT_DIR}${FILENAME}"/"${FILENAME}.sfv"
	# before paring, we would like to know if everything is OK with additional files
	if [ -n "$ADD_TO_PAR" ]
	then
		check_files
	fi
}

genpasswd() {
	# Store original RARC variable
	if [ -z "$ORIGINAL_RARC" ]
	then
		ORIGINAL_RARC=$RARC
	fi
	# Random password generation
	if [ "$RND_PASSWD" = "1" ]
	then
		if [ -z "$PASSWORD_LENGTH" ]
		then
			echo "ERROR: Password length was not specified."
			exit 1
		fi
		PASSWORD=$(cat /dev/urandom | tr -dc '[:alnum:]' | head -c $PASSWORD_LENGTH)
		echo "Your password for the current rar: $PASSWORD"
		RARC="${ORIGINAL_RARC} -hp${PASSWORD}"
	fi
}

# Simple help. Maybe there is a better way to do this, but this should be fine for a time being.
show_help() {
	echo "Rar&Par script version 0.81. Copyright (C) 2011-2013 Tadeus Dobrovolskij."
	echo -e "Comes with ABSOLUTELY NO WARRANTY. Distributed under GPL v2 license(\033[4mhttp://www.gnu.org/licenses/gpl-2.0.txt\033[0m).\n"
	echo "Script helps you prepare your files for Usenet. Each file in the current directory is archived with RAR, then par2 files are created."
	echo -e "Must have par2 and rar installed (obviously).\n"
	echo "For the full functionality you will also need: coreutils(present on almost any distro), cksfv, newsmangler and mediainfo."
	echo -e "Usage: $0 [options]\n"
	echo -e "OR (to start with \033[1mdefault\033[0m options): $0 --defaults\n"
	echo -e "Options:\n"
	echo -e "\t-b <size>\tPar block size. Default: \033[1m768000\033[0m"
	echo -e "\t-B <count>\tPar block count. Takes precedence over \033[1m-b\033[0m option."
	echo -e "\t-c <file>\tUse config file."
	echo -e "\t-d\t\tCreates directory for each processed file's rar and par2 files."
	echo -e "\t--defaults\tLaunch the script with default options."
	echo -e "\t-D <dir>\tStarting directory."
	echo -e "\t-e <expr>\tComma separated list of expressions to exclude. Example: \"*avi\",\"*mpg\" to exclude all avi and mpg files. File mode only."
	echo -e "\t-h\t\tDisplay this message. Same as '--help'."
	echo -e "\t-l\t\tLimit size of par2 recovery files (Don't use both -u and -l)."
	echo -e "\t-m <0..5>\tRar compression level (0-store...5-maximal). Default: \033[1m0\033[0m"
	echo -e "\t-M <algorithm>\tCryptorenaming mode. Choose from sha1, sha224, sha256, sha384, sha512, md5 algorithms."
	echo -e "\t-min <size>\tProcess only the files larger than <size> megabytes."
	echo -e "\t-n\t\tuse old style rar file names."
	echo -e "\t-N\t\tCreate .nfo file for processed media files. Works only in file(default) mode."
	echo -e "\t-NN <string>\tNew name. Rename file/directory during processing. Shouldn't be used with multiple items. Disabled in recursive mode."
	echo -e "\t-O <dir>\tOutput directory."
	echo -e "\t-p <string>\tFile name prefix."
	echo -e "\t--par <list>\tComma separated list of files to include additionally in a par set."
	echo -e "\t-P <string>\tProtect files with <string> as password."
	echo -e "\t-PR <length>\tSame as -P, but password(of specified length) is generated by the script and printed to stdout."
	echo -e "\t-r <%%>\t\tPar recovery per cent. Default: \033[1m10\033[0m"
	echo -e "\t--rar <list>\tComma separated list of files to include additionally in a rar set."
	echo -e "\t-R\t\tRecursive mode. Works only while processing files."
	echo -e "\t-s <string>\tFile name suffix."
	echo -e "\t--sfv\t\tCreate SFV(Simple File Verification) file."
	echo -e	"\t--subdir\tRar&Par not the files, but subdirectories"
	echo -e "\t-u\t\tUniform par2 recovery file size."
	echo -e "\t-U\t\tUpload processed files automatically."
	echo -e "\t-v <MB>\t\tRar volume size in megabytes. Default:  \033[1m50\033[0m"
	echo -e "\t-V\t\tBe verbose."
	echo -e "\t-X <path>\tFull path to newsmangler eXecutable.\n"
}
# Display help if no options were provided
if [ "$#" == "0" ]
then
	show_help
	exit
fi
# Initialize variables and set them to the default values
defaults
# Options parser. Checks options beginning with a dash("-") symbol.
while [[ $1 = -* ]]; do
	case "$1" in
		-b)
		 BLOCK_SIZE="$2"
		 shift 2
		 ;;
		-B)
		 BLOCK_COUNT="$2"
		 shift 2
		 ;;
		-c)
		 CONFIG="$2"
		 shift 2
		 ;;
		-d)
		 DIRECTORIES=1
		 shift
		 ;;
		--debug)
		 DEBUG=yes
		 shift
		 ;;
		--defaults)
		 DEFAULTS=yes
		 break
		 ;;
		-D)
		 STARTING_DIR="$2"
		 shift 2
		 ;;
		-e)
		 EXCLUDE_LIST="$2"
		 shift 2
		 ;;
		-h|--help)
		 show_help
		 exit
		 ;;
		-l)
		 LIMIT=1
		 shift
		 ;;
		-m)
		 COMPRESSION="$2"
		 shift 2
		 ;;
		-M)
		 CRYPTMODE=1
		 ALGO="$2"
		 shift 2
		 ;;
		-min)
		 MINIMUMS="$2"
		 shift 2
		 ;;
		-n)
		 OLDRAR=1
		 shift
		 ;;
		-N)
		 NFO=1
		 shift
		 ;;
		-NN)
		 RENAME_TO="$2"
		 shift 2
		 ;;
		-O)
		 OUTPUT_DIR="$2"
		 shift 2
		 ;;
		-p)
		 NAME_PREFIX="$2"
		 shift 2
		 ;;
		--par)
		 ADD_TO_PAR="$2"
		 shift 2
		 ;;
		-P)
		 PASSWORD="$2"
		 shift 2
		 ;;
		-PR)
		 RND_PASSWD=1
		 PASSWORD_LENGTH="$2"
		 shift 2
		 ;;
		-r)
		 PAR_RECOVERY="$2"
		 shift 2
		 ;;
		--rar)
		 ADD_TO_RAR="$2"
		 shift 2
		 ;;
		-R)
		 RECURSIVE=1
		 shift
		 ;;
		-s)
		 NAME_SUFFIX="$2"
		 shift 2
		 ;;
		--sfv)
		 CREATE_SFV=1
		 shift
		 ;;
		--subdir)
		 SUBDIRECTORIES=1
		 shift
		 ;;
		-u)
		 UNIFORM=1
		 shift
		 ;;
		-U)
		 UPLOAD=1
		 shift
		 ;;
		-v)
		 VOLUME_SIZE="$2"
		 shift 2
		 ;;
		-V)
		 VERBOSE=1
		 shift
		 ;;
		-X)
		 PATH_TO_MANGLER="$2"
		 shift 2
		 ;;
		*)
		 echo "Error: Unknown option: $1" >&2
		 show_help
		 exit 1
		 ;;
	esac
done
# Run a script with default settings if a user wants it.
if [ "$DEFAULTS" = "yes" ]
then
	defaults
fi
# Load config
if [ -n "$CONFIG" ] && [ -e "$CONFIG" ]
then
	. "$CONFIG"
elif [ -n "$CONFIG" ] && [ ! -e "$CONFIG" ]
then
	echo "ERROR: Configuration file doesn't exist."
	exit 1
fi
# Debug mode
if [ "$DEBUG" = "yes" ]
then
	set -x
fi

if [ "$CRYPTMODE" = "1" ] && [ "$ALGO" != "sha1" ] && [ "$ALGO" != "sha224" ] && [ "$ALGO" != "sha256" ] && [ "$ALGO" != "sha384" ] && [ "$ALGO" != "sha512" ] && [ "$ALGO" != "md5" ]
then
	echo "$ALGO hash algorithm unsupported!"
	show_help
	exit 1
fi

# Check if we have mediainfo installed
if [ "$NFO" = "1" ]
then
	type mediainfo > /dev/null 2>&1 || { echo "Error: mediainfo application not found! Can't create .nfo!"; exit 1; }
fi

#Check if we have cksfv installed
if [ "$CREATE_SFV" = "1" ]
then
        type cksfv > /dev/null 2>&1 || { echo "Error: cksfv tool not found! Can't create .sfv!"; exit 1; }
fi

# Check if newsmangler binary was specified
if (( $UPLOAD==1 ))
then
	if [ -z "$PATH_TO_MANGLER" ] && ! type mangler.py > /dev/null 2>&1
	then
		echo "Error: Please specify the path to newsmangler executable file."
		echo "Upload not possible. Quiting..."
		exit 1
	fi
	if [ -z "$PATH_TO_MANGLER" ] && type mangler.py > /dev/null 2>&1
	then
		PATH_TO_MANGLER="mangler.py"
	fi
fi

# If starting directory is specified - move there
if [ -n "$STARTING_DIR" ]
then
	if [ -d "$STARTING_DIR" ]
	then
		pushd . > /dev/null 2>&1
		cd "$STARTING_DIR"
	else
		echo "ERROR: Specified starting directory doesn't exist!"
		exit 1
	fi
# we want to remember where we were(for some future function calls)
else
	STARTING_DIR=$(pwd)
fi

# Check if output dir ends with slash and if it exists
if [ -n "$OUTPUT_DIR" ]
then
	[[ "$OUTPUT_DIR" != */ ]] && OUTPUT_DIR="${OUTPUT_DIR}/"
	[ -d "$OUTPUT_DIR" ] || mkdir -p "$OUTPUT_DIR"
else
	OUTPUT_DIR="./"
fi

# Exclusions
if [ -n "$EXCLUDE_LIST" ]
then
	EXCLUDE_LIST=$(echo "$EXCLUDE_LIST" | sed -e 's/^/! -iname \"/' -e 's/,/\" ! -iname \"/g' -e 's/$/\" /')
fi

# Do we want to add some additional files to our parset?
if [ -n "$ADD_TO_PAR" ]
then
	ADD_TO_PAR=$(echo -n $ADD_TO_PAR | sed -e 's/,/ /g')
fi

# Do we want to add some additional files to our rarset?
if [ -n "$ADD_TO_RAR" ]
then
	ADD_TO_RAR=$(echo -n $ADD_TO_RAR | sed -e 's/,/ /g')
fi

# Setting up rar command to be exactly like we need it to be.
RARC="rar a -rr1 -m${COMPRESSION} -v${VOLUME_SIZE}m -ed"
if (( $OLDRAR==1 )); then
	RARC="${RARC} -vn"
fi

# Do we need to password protect files?
if [ -n "$PASSWORD" ] && [ -z "$RND_PASSWD" ]
then
	RARC="${RARC} -hp${PASSWORD}"
fi

# Same for par2 command.
if (( $BLOCK_COUNT > 0 ))
then
	PAR2C="par2 c -b${BLOCK_COUNT} -r${PAR_RECOVERY}"
else
	PAR2C="par2 c -s${BLOCK_SIZE} -r${PAR_RECOVERY}"
fi
if (( $UNIFORM==1 )); then
	PAR2C="${PAR2C} -u"
fi
if (( $UNIFORM==0 )) && (( $LIMIT==1)); then
	PAR2C="$PAR2C -l"
fi

# First, we look for all files in current directory according to our minimum size limit.
if (( $SUBDIRECTORIES==1 ))
then
	RARC="${RARC} -r"
	# We need some other directory name, because otherwise we will encounter conflicts
	if [ -z $NAME_SUFFIX ] && [ -z $NAME_PREFIX ]; then NAME_SUFFIX="-rnp"; fi
	if (($(find -L ${MAXDEPTH} -type d -name '*' ! -name '.*' | wc -l) > 0)); then
		while read DIRECTORY_TO_PROCESS; do
			echo "Processing: $DIRECTORY_TO_PROCESS"
			if [ -n "$RENAME_TO" ] && [ "$RECURSIVE" == "0" ]
			then
				FILENAME="$NAME_PREFIX""$RENAME_TO""$NAME_SUFFIX"
			else
				FILENAME="$NAME_PREFIX""$DIRECTORY_TO_PROCESS""$NAME_SUFFIX"
			fi
			ORIGINAL_NAME="$FILENAME"
			# if it's needed, generate password
			genpasswd
			# Cryptorenaming
			if (( $CRYPTMODE==1 ))
			then
				FILENAME=$(echo -n "$FILENAME" | ${ALGO}sum | sed -e 's/[[:space:]].*//')
			fi
			mkdir "${OUTPUT_DIR}${FILENAME}"
			[ "$CRYPTMODE" = "1" ] && generate_nfo_header > "${OUTPUT_DIR}${FILENAME}"/"${ORIGINAL_NAME}.nfo"
			# If verbosity option is set, then output all the stuff to stdo. 
			if (( $VERBOSE==1 )); then
				$RARC "${OUTPUT_DIR}${FILENAME}"/"${FILENAME}".rar "$DIRECTORY_TO_PROCESS" $ADD_TO_RAR
				create_sfv_and_run_check
				$PAR2C "${OUTPUT_DIR}${FILENAME}"/"${FILENAME}".par2 "${OUTPUT_DIR}${FILENAME}"/"${FILENAME}"*.r* $ADD_TO_PAR
			else
			# Otherwise just continue.
				$RARC "${OUTPUT_DIR}${FILENAME}"/"${FILENAME}".rar "$DIRECTORY_TO_PROCESS" $ADD_TO_RAR > /dev/null 2>&1
				create_sfv_and_run_check
				$PAR2C "${OUTPUT_DIR}${FILENAME}"/"${FILENAME}".par2 "${OUTPUT_DIR}${FILENAME}"/"${FILENAME}"*.r* $ADD_TO_PAR > /dev/null 2>&1
			fi
			# If we are adding additional files to a parset, we probably want them in the output directory
			if [ -n "$ADD_TO_PAR" ]
			then
				cp -ut "${OUTPUT_DIR}${FILENAME}"/ $ADD_TO_PAR > /dev/null 2>&1
			fi
			# Upload files with newsmangler if needed
			if (( $UPLOAD==1 ))
			then
				# We want to skip nfo in cryptomode, because it shows the real file name
				if (( $CRYPTMODE==1 ))
				then
					mv "${OUTPUT_DIR}${FILENAME}"/"${ORIGINAL_NAME}.nfo" /tmp/
				fi
				"$PATH_TO_MANGLER" "${OUTPUT_DIR}${FILENAME}"
				if (( $CRYPTMODE==1 ))
				then
					mv /tmp/"${ORIGINAL_NAME}.nfo" "${OUTPUT_DIR}${FILENAME}"/
				fi
				# move nzb to the output directory
				NEWSMANGLER_NZB=$(echo -n "newsmangler_${FILENAME}.nzb" | sed -e 's/ /_/g' )
				[ -e $NEWSMANGLER_NZB ] && mv $NEWSMANGLER_NZB "${OUTPUT_DIR}${FILENAME}"/${NEWSMANGLER_NZB#newsmangler_}
			fi
			# Store rared files in separate directory?
			if (( $DIRECTORIES==0 )); then
				mv "${OUTPUT_DIR}${FILENAME}"/* "${OUTPUT_DIR}"
				rmdir "${OUTPUT_DIR}${FILENAME}"/
			fi
		done < <(find -L ${MAXDEPTH} -type d -name "*" ! -name ".*" | sed -e 's/^\.//g' -e 's/^\///g')
	else
		echo "Error: No directories to process!"
		exit 1
	fi
else
	RARC="${RARC} -ep"
	(( $RECURSIVE == 1 )) && MAXDEPTH=""
	if (($(find . ${MAXDEPTH} -type f \( ! -iname ".*" ${EXCLUDE_LIST}\) -size +${MINIMUMS}M | wc -l) > 0)); then
		while read FILE_TO_PROCESS; do
			echo "Processing: $FILE_TO_PROCESS"
			if (( $RECURSIVE == 1 ))
			then
				pushd . > /dev/null 2>&1
				cd $(dirname "$FILE_TO_PROCESS")
				FILE_TO_PROCESS=$(basename "$FILE_TO_PROCESS")
			fi
			if [ -n "$RENAME_TO" ] && [ "$RECURSIVE" == "0" ]
			then
				FILENAME="$NAME_PREFIX""$RENAME_TO""$NAME_SUFFIX"
			else
				FILENAME="$NAME_PREFIX""${FILE_TO_PROCESS%.*}""$NAME_SUFFIX"
			fi
			EXT="${FILE_TO_PROCESS##*.}"
			# Get media info
			if (( $NFO == 1 ))
			then
				for i in ${SUPPORTED_BY_MINFO[@]}
				do
					if [[ "$i" == "$EXT" ]]
					then
						generate_nfo_header > /tmp/rarnpar_nfo.tmp
						mediainfo "$FILE_TO_PROCESS" >> /tmp/rarnpar_nfo.tmp
						break
					fi
				done
			fi
			ORIGINAL_NAME="$FILENAME"
			# if it's needed, generate password
			genpasswd
			# Cryptorenaming
			if (( $CRYPTMODE==1 ))
			then
				ORIGINAL_FILE_EXT="$FILE_TO_PROCESS"
				ORIGINAL_FILE="${FILE_TO_PROCESS%.*}"
				FILENAME=$(echo -n "$FILENAME" | ${ALGO}sum | sed -e 's/[[:space:]].*//')
				# We don't need to rename files if we encypt rar with password
				if [ -z $PASSWORD ]
				then
					mv "$FILE_TO_PROCESS" "${FILENAME}.${EXT}"
					FILE_TO_PROCESS="${FILENAME}.${EXT}"
				fi
			fi
			mkdir "${OUTPUT_DIR}${FILENAME}"
			# Nfo file creation
			if (( $CRYPTMODE==1 )) && (( $NFO == 1 )) && [ -e /tmp/rarnpar_nfo.tmp ]
			then
				cat /tmp/rarnpar_nfo.tmp >> "${OUTPUT_DIR}${FILENAME}"/"${ORIGINAL_NAME}.nfo"
			elif (( $CRYPTMODE==1 )) && (( $NFO == 0 ))
			then
				generate_nfo_header > "${OUTPUT_DIR}${FILENAME}"/"${ORIGINAL_NAME}.nfo"
			elif (( $CRYPTMODE==0 )) && (( $NFO == 1 )) && [ -e /tmp/rarnpar_nfo.tmp ]
			then
				cat /tmp/rarnpar_nfo.tmp >> "${OUTPUT_DIR}${FILENAME}"/"${FILENAME}.nfo"
			elif (( $CRYPTMODE==1 )) && (( $NFO == 1 )) && ! [ -e /tmp/rarnpar_nfo.tmp ]
			then
				generate_nfo_header > "${OUTPUT_DIR}${FILENAME}"/"${ORIGINAL_NAME}.nfo"
			fi
			[ -e /tmp/rarnpar_nfo.tmp ] && rm /tmp/rarnpar_nfo.tmp
			# If verbosity option is set, then output all the stuff to stdo. 
			if (( $VERBOSE==1 )); then
				$RARC "${OUTPUT_DIR}${FILENAME}"/"${FILENAME}".rar "$FILE_TO_PROCESS" $ADD_TO_RAR
				create_sfv_and_run_check
				$PAR2C "${OUTPUT_DIR}${FILENAME}"/"${FILENAME}".par2 "${OUTPUT_DIR}${FILENAME}"/"${FILENAME}"*.r* $ADD_TO_PAR
			else	
			# Otherwise just continue.
				$RARC "${OUTPUT_DIR}${FILENAME}"/"${FILENAME}".rar "$FILE_TO_PROCESS" $ADD_TO_RAR > /dev/null 2>&1
				create_sfv_and_run_check
				$PAR2C "${OUTPUT_DIR}${FILENAME}"/"${FILENAME}".par2 "${OUTPUT_DIR}${FILENAME}"/"${FILENAME}"*.r* $ADD_TO_PAR > /dev/null 2>&1
			fi
			# If we are adding additional files to a parset, we probably want them in the output directory
			if [ -n "$ADD_TO_PAR" ]
			then
				cp -ut "${OUTPUT_DIR}${FILENAME}"/ $ADD_TO_PAR > /dev/null 2>&1
			fi
			# Upload files with newsmangler if needed
			if (( $UPLOAD==1 ))
			then
				# We want to skip nfo in cryptomode, because it shows the real file name
				if (( $CRYPTMODE==1 ))
				then
					mv "${OUTPUT_DIR}${FILENAME}"/"${ORIGINAL_NAME}.nfo" /tmp/
				fi
				"$PATH_TO_MANGLER" "${OUTPUT_DIR}${FILENAME}"
				if (( $CRYPTMODE==1 ))
				then
					mv /tmp/"${ORIGINAL_NAME}.nfo" "${OUTPUT_DIR}${FILENAME}"/
				fi
				# move nzb to the output directory
				NEWSMANGLER_NZB=$(echo -n "newsmangler_${FILENAME}.nzb" | sed -e 's/ /_/g' )
				[ -e $NEWSMANGLER_NZB ] && mv $NEWSMANGLER_NZB "${OUTPUT_DIR}${FILENAME}"/${NEWSMANGLER_NZB#newsmangler_}
			fi
			# Store rared files in separate directory?
			if (( $DIRECTORIES==0 )); then
				mv "${OUTPUT_DIR}${FILENAME}"/* "${OUTPUT_DIR}"
				rmdir "${OUTPUT_DIR}${FILENAME}"/
			fi
			[ "$CRYPTMODE" = "1" ] && [ -z "$PASSWORD" ] && mv "$FILE_TO_PROCESS" "$ORIGINAL_FILE_EXT"
			if (( $RECURSIVE == 1 ))
                        then
				popd > /dev/null 2>&1
			fi
		done < <(find . ${MAXDEPTH} -type f \( ! -iname ".*" ${EXCLUDE_LIST}\) -size +${MINIMUMS}M | sed -e 's/^\.//g' -e 's/^\///g')
		else
			echo "Error: No files to process!"
			exit 1
	fi
fi
if [ -n "$STARTING_DIR" ]
then
	popd > /dev/null 2>&1
fi
echo "Task completed."
