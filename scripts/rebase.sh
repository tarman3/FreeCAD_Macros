#!/bin/bash

# Fist argument uses as a path to local repository

# Branches names
main_branch="main"      # name of the main branch of repository
default_branch="CAM3"   # return to this branch after all finished successfully

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

path="$1"
if [ -n "$path" ]; then
    cd $path
else
    path="$PWD"
fi

echo
echo "--- Script to rebase muplitple branches ---"
echo
echo "    Local path: $PWD"
echo

branches=`git branch --format='%(refname:short)'`
array=($branches)

counter=0
rebased=0
all=false
this=false

for branch in ${array[@]}; do
    if [ "$branch" == "${main_branch}" ]; then
        # skip main branch
        continue
    fi

    counter=$((counter+1))
    counterf=$(printf "%-2s" "$counter")
    echo

    if $all; then
        # force confirm for all branches
        echo -e "$counterf - ${GREEN}$branch${NC}"
    else
        echo -n "$counterf - Rebase branch: $branch (N/y/all) ? "
        read answer
        if [[ "$answer" == "" ]] || [[ "$answer" == "n" ]] || [[ "$answer" == "N" ]]; then
            this=false
        elif [[ "$answer" == "y" ]] || [[ "$answer" == "Y" ]]; then
            this=true
        elif [[ "$answer" == "all" ]] || [[ "$answer" == "All" ]] || [[ "$answer" == "ALL" ]]; then
            this=true
            all=true
        else
            echo
            echo -e "${RED}     Wrong input. Exit${NC}"
            echo
            exit
        fi
    fi

    if $this; then
        git checkout "$branch" --quiet
        git rebase ${main_branch}
        result=$?
        if [ "$result" == "0" ]; then
            rebased=$((rebased+1))
        else
            echo -n "Abort and continue rebase next branch (N/y) ? "
            read answer
            if [[ "$answer" == "y" ]] || [[ "$answer" == "Y" ]]; then
                git rebase --abort
            else
                echo
                echo -e "\n${RED}-------------------------"
                echo "Rebase completed with code: $result"
                echo "Total branches:       ${#array[@]}"
                echo "Branches processed:   $counter"
                echo "Rebased successfully: $rebased"
                echo -e "-------------------------${NC}"
                exit
            fi
        fi

    else
        echo "     skipped"
    fi

done

echo
echo
echo -e "${GREEN}-------------------------"
echo "Total branches:       ${#array[@]}"
echo "Branches processed:   $counter"
echo "Rebased successfully: $rebased"
echo -e "-------------------------${NC}"
echo
echo
git checkout "${default_branch}"
echo
