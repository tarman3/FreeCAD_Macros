path="$1"
cd $path

echo
echo "--- Script to rebase muplitple branches ---"

echo -n "    Rebase all branches: (N/y) ? "
read rebaseAll

if [[ $rebaseAll == "y" ]] || [[ $rebaseAll == "Y" ]]; then
    all=true
else
    all=false
fi

branches=`git branch --format='%(refname:short)'`
# echo $branches
# echo

array=($branches)

counter=0
rebased=0
for branch in $branches; do
    if [ "$branch" == "main" ]; then
        continue
    fi
    counter=$((counter+1))
    counterf=$(printf "%-2s" "$counter")
    echo

    if [ $all == true ]; then
        echo "$counterf - $branch"
        confirm="y"
    else
        echo -n "$counterf - Rebase branch: $branch (N/y) ? "
        read confirm
        if [[ "$confirm" != "" ]] && [[ "$confirm" != "y" ]] && [[ "$confirm" != "Y" ]] && [[ "$confirm" != "n" ]] && [[ "$confirm" != "N" ]]; then
            echo
            echo "     Wrong input. Exit"
            echo
            exit
        fi
    fi

    if [[ "$confirm" == "y" ]] || [[ "$confirm" == "Y" ]]; then
        git checkout "$branch"
        git rebase main

        result=$?
        echo "output $result"
        if [ "$result" != "0" ]; then
            echo
            echo "Total branches:       ${#array[@]}"
            echo "Branches processed:   $counter"
            echo "Rebased successfully: $rebased"
            exit
        else rebased=$((rebased+1))
        fi

    else
        echo "     skipped"
    fi

done

echo
echo
echo "----------------------------------"
echo "Total branches:       ${#array[@]}"
echo "Branches processed:   $counter"
echo "Rebased successfully: $rebased"
echo "----------------------------------"
echo
echo
git checkout CAM3
echo
