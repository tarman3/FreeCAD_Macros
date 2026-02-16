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
echo -n "    Rebase all branches: (N/y) ? "
read rebaseAll

if [[ $rebaseAll == "y" ]] || [[ $rebaseAll == "Y" ]]; then
    all=true
else
    all=false
fi

branches=`git branch --format='%(refname:short)'`
array=($branches)

counter=0
rebased=0
for branch in ${array[@]}; do
    if [ "$branch" == "${main_branch}" ]; then
        # skip main branch
        continue
    fi

    counter=$((counter+1))
    counterf=$(printf "%-2s" "$counter")
    echo

    if [ $all == true ]; then
        # force confirm for all branches
        confirm="y"
        echo "$counterf - $branch"
    else
        echo -n "$counterf - Rebase branch: $branch (N/y) ? "
        read confirm
        if [[ -n "$confirm" ]] \
        && [[ "$confirm" != "y" ]] && [[ "$confirm" != "Y" ]] \
        && [[ "$confirm" != "n" ]] && [[ "$confirm" != "N" ]]; then
            echo
            echo -e "${RED}     Wrong input. Exit${NC}"
            echo
            exit
        fi
    fi

    if [[ "$confirm" == "y" ]] || [[ "$confirm" == "Y" ]]; then
        git checkout "$branch"
        git rebase ${main_branch}
        result=$?
        if [ "$result" != "0" ]; then
            echo
            echo -e "\n${RED}-------------------------"
            echo "Rebase completed with code: $result"
            echo "Total branches:       ${#array[@]}"
            echo "Branches processed:   $counter"
            echo "Rebased successfully: $rebased"
            echo -e "-------------------------${NC}"
            exit
        else
            rebased=$((rebased+1))
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