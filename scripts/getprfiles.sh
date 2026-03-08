#!/bin/bash

# Example of execution:
# bash getprfiles.sh 26766

# argument 1: pull request number
# argument 2: path to local repository

default_local_rep="$HOME/projects/FreeCAD_git"  # uses if no argument 2
temp_dir="/tmp"                                 # path to save files from pull request

# ------------------------------------------------------------------------------------

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

if [ "$1" == "" ]; then
    echo
    echo -n "    Type number of pull request: "
    read answer
    pr="${answer}"
else
    pr="$1"
fi

if [[ ! "$pr" =~ ^[0-9]+$ ]]; then
    echo
    echo -e "    ${RED}Error:${NC} PR should contains only numbers"
    echo
    exit
fi

if [ "$2" == "" ]; then
    local_rep="${default_local_rep}"
else
    local_rep="$2"
fi

mkdir --parents "${temp_dir}/${pr}"

link="https://github.com/FreeCAD/FreeCAD/pull/$pr"
file_diff="${temp_dir}/${pr}/${pr}.diff"
curl -s -L "${link}.diff" > "${file_diff}"

files_list="${temp_dir}/${pr}/${pr}.txt"
cat "${file_diff}" | grep "diff --git" | sort | cut -d" " -f4 | cut -c3- > "${files_list}"

file_patch="${temp_dir}/${pr}/${pr}.patch"
curl -s -L "${link}.patch" > "${file_patch}"

echo
cat "${file_patch}" | sed -n '/diff/q;p'| sed -n '/---/,$p' | tail -n +2

if [ ! -f "${files_list}" ]; then
    echo
    echo -e "    ${RED}Error:${NC} Not created file \"${files_list}\""
    echo
    exit
fi

amount=`sed -n '$=' "${files_list}"`
if [[ -z "$amount" ]]; then
    echo
    echo -e "    ${RED}Error:${NC} Can not define files. Check pull request number"
    echo
    exit
fi

link_api="https://api.github.com/repos/FreeCAD/FreeCAD/pulls/$pr"
json="${files_list%.*}.json"
curl -s -H "Accept: application/vnd.github+json" "${link_api}" > "$json"

if [ ! -f "$json" ]; then
    echo
    echo -e "    ${RED}Error:${NC} Not created file \"$json\""
    echo
    exit
fi

if `command -v jq > /dev/null`; then
    user=`cat $json | jq -r ".user.login"`
    branch=`cat $json | jq -r ".head.ref"`
    title=`cat $json | jq -r ".title"`
    commits=`cat $json | jq -r ".commits"`
else
    user=`cat "$json" | grep -m 1 -oP '"login": "\K[^"]+'`
    branch=`cat "$json" | grep -m 1 -oP '"ref": "\K[^"]+'`
    title=`cat "$json" | grep -m 1 -oP '"title": "\K[^"]+'`
    commits=`cat "$json" | grep -oP '"commits": \K[^,]+' | tail -n 1`
fi

echo
echo -e "Title:   ${GREEN}$title${NC} #$pr"
echo "User:    $user"
echo "Branch:  $branch"
echo "Commits: $commits"
echo "Files:   $amount"
echo "Link:    $link"
echo

if [ $amount -lt 11 ]; then
    cat "${files_list}"
fi

saved=false

if [ -f `head -n 1 ${files_list}` ]; then
    echo
    echo -n "    Copy files from $PWD: (N/y) ? "
    read answer
    if [[ "$answer" == "y" ]] || [[ "$answer" == "Y" ]]; then
        saved=true
        while read file; do
            rsync --checksum --recursive --mkpath "$file" "${temp_dir}/$pr/$file"
        done < "${files_list}"
    fi
fi

if [ $saved == false ]; then
    echo
    echo -n "    Download files from GitHub: (N/y) ? "
    read answer
    if [[ "$answer" == "y" ]] || [[ "$answer" == "Y" ]]; then
        saved=true
        counter=0
        while read file; do
            counter=$((counter+1))
            link="https://raw.githubusercontent.com/$user/FreeCAD/refs/heads/$branch/$file"
            echo
            echo -e "$counter/$amount ${GREEN}$file${NC}"
            curl --progress-bar "$link" --create-dirs --output "${temp_dir}/$pr/$file"
            if [ `sed -n '$=' "${temp_dir}/$pr/$file"` -eq 1 ]; then
                line=`cat "${temp_dir}/$pr/$file"`
                if [ "$line" == "404: Not Found" ]; then
                    echo -e "${RED}File was removed${NC}"
                    cat /dev/null > "${temp_dir}/$pr/$file"
                fi
            fi
        done < "${files_list}"
    fi
fi

if [ $saved == true ]; then
    echo
    echo "Files saved to ${temp_dir}/$pr"
    echo
else
    exit
fi

if [ -d "$local_rep" ]; then
    echo
    echo -n -e "$    Copy files from PR to local repository ${local_rep}: (N/y) ? "
    read answer
    echo
    if [[ "$answer" == "y" ]] || [[ "$answer" == "Y" ]]; then
        while read file; do
            rsync --checksum --recursive --mkpath "${temp_dir}/$pr/$file" "${local_rep}/$file"
        done < "${files_list}"
    fi
fi
