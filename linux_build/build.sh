#!/bin/sh

# build.sh for few disassembled mega drive games
# By zucca@kahvipannu.com
# License: BSD
# Major dependencies are
#     - asl, the macro assembler
#     - gawk 4.1.1 or newer for inline patching
#     - gcc only for compiling the p2bin
#
# Note that this script may reside anywhere in the filesystem.
# Also running this script outside of the directory where the assembly is allowed.

: ${ASlog:="AS.log"}

# Warning messages. (We may pretty the output later.)
warn() {
    echo -e "$*" 1>&2
}

# Maybe overkill for such a simple script
# but we have now a function for exiting.
errexit() {
    if grep -E '^[0-9]+$' <<< "$1"
    then
	# First argument was a number. We use it as an exit code.
        ec="$1"
        shift
    fi
    warn "$*"
    exit "${ec:=1}"
}

# Path patching using awk.
# While we're at it replace paths with absolute ones.
# Why? I didn't find any way to tell asl
# from which diretory to search for includes.
path_patch() {
    # We are using gawk. Would maybe be better to use POSIX awk instead...
    gawk -i inplace -v "includedir=${includedir}" '{if (/b?include\s+"/) { sub("\"","\"" includedir "/"); gsub("\\\\","/") } print }' "$@"
}

# Go trough CLI switches.
while [ "${1:0:1}" = "-" ]
do
    case "$1" in
        --p2bin)
            if [ "$2" ] && [ -x "$2" ]
            then
                p2bin="$2"
                shift
            else
                errexit "Invalid argument to ${1}. Is '${2}' an executable?"
            fi
        ;;
        --keep-temp)
            keeptemp=1
        ;;
        --stdout)
            stdout=1
        ;;
        --help)
            cat README.adoc || exit 1
            exit 0
        ;;
        --)
            shift
            break
        ;;
        *)
            warn "Not a _slightest_ clue what to do with that $1 switch of yours."
            errexit "Tip. Use '--' to break switch searching. Exiting..."
        ;;
    esac
    shift
done

if [ "$stdout" ]
then
    msg() { return 0; }
else
    msg() { echo -e "$*"; }
fi

# Test arguments and existence of provided assembly file.
[ "$1" ] || errexit "USAGE: ${0##*/} <assembly file> <output binary>\n       ${0##*/} --stdout <assembly file>"
if [ ! "$2" ] && [ ! "$stdout" ]
then
    errexit "No output file specified."
fi

outbin="$2"

workdir="$(mktemp -td AS_tmp_XXXXXX)"

# Set include dir to the directory where the assembly file is.
includedir="$(readlink -f "$1")"
includedir="${includedir%/*}"

templog="${workdir}/${ASlog##*/}"
temp_p="${workdir}/out.p"
temp_h="${workdir}/out.h"

# Copy files to our temporary directory.
cp "$1" "$workdir"

asmfile="${workdir}/${1##*/}"

# Move into the said directory.
#push "$workdir" # Probably a bad choice. Hard to define absolute paths reliably when output binary is still non-existent.

# Patch and compile the assembly.
path_patch "$asmfile" && msg "Path patch applied..." || errexit "Patching failed. '$tempdir' -directory is left undeleted."
asl -xx -c -A -l -shareout "$temp_h" -o "$temp_p" "$asmfile" > "$templog" 2>&1 \
    && msg Source compiled... \
    || errexit "Source compiling failed. Temporary files are left intact inside '${workdir}' -directory."



# Find source and compile the p2bin program if needed.
if ! [ -e "${p2bin:=${includedir}/p2bin}" ]
then
    p2bin_source="$(find "$includedir" -name '*p2bin.c')"
    if [ "$(wc -l <<< "$p2bin_source")" -eq "1" ]
    then
        if gcc -O3 -w -o "$p2bin" "$p2bin_source"
        then
            msg "p2bin compiled..."
        else
            rm -r "$workdir"
            warn "Compiling p2bin failed."
            test -e "$p2bin" && rm "$p2bin"
            errexit "Aborting..."
        fi
    fi

# Just in case user provided the binary we'll check if it's an executable.
elif ! [ -x "$p2bin" ]
then
    warn "'${p2bin}' isn't executable."
    rm -r "$workdir"
    errexit "Aborting..."
fi

if ! [ "$stdout" ]
then
    "$p2bin" "$temp_p" "$2" "$temp_h" > /dev/null && msg "Succesfully created '$2'." || errexit "p2bin failed to create the final binary."
else
    # A poor man's stdout method.
    "$p2bin" "$temp_p" "${workdir}/out.bin" "$temp_h" > /dev/null && msg "Succesfully created '$2'." || errexit "p2bin failed to create the final binary."
    cat "${workdir}/out.bin"
fi

test "$keeptemp" && msg "Temp files left into '${workdir}'" || rm -r "$workdir"
