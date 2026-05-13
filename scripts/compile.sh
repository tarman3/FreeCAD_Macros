#!/bin/bash

pathBuild="/home/user/projects/FreeCAD_build"  # build to this dir
pathSrc="/home/user/projects/FreeCAD_src"      # build from this dir
pathGit="/home/user/projects/FreeCAD_git"      # contains .git
myBranch="CAM3"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# remove simlink if present
if [ -h "${pathSrc}/.git" ]; then
    unlink "${pathSrc}/.git"
fi

if [ -d "${pathGit}/.git" ]; then
    branch=`git -C "${pathGit}" branch --show-current`
    echo
    echo "Selected branch: $branch"

    if [ "$branch" != "$myBranch" ]; then
        echo
        read -p "Type 'Yes' to continue or press Enter to use $myBranch branch" answer
        if [[ "$answer" != "Yes" ]] && [[ "$answer" != "yes" ]]; then
            git -C "${pathGit}" checkout $myBranch
        fi
    fi
fi

if [ "${pathSrc}" != "${pathGit}" ]; then
    echo
    rsync_log=`rsync --verbose --checksum --recursive --delete --exclude-from="compile_exclude" "${pathGit}/" "${pathSrc}/"`
    echo "${rsync_log}"
    if [[ "${rsync_log}" == *"CMakeLists"* ]]; then
        echo
        echo -e "${GREEN}Force reconfigure and create simlink to .git${NC}"
        sleep 1
        reconf="y"
    fi
fi

arg2="$2"

if [[ "$arg2" == "c" ]] || [[ "$arg2" == "config" ]] || [[ "$arg2" == "configure" ]] \
|| [[ "$reconf" == "y" ]] || [[ "$reconf" == "Y" ]]; then
    echo
    echo "cmake configure"
    echo

    # create simlink before reconfigure, which allow to update about info
    ln -s "${pathGit}/.git" "${pathSrc}/.git"

    cmake \
        -D CMAKE_BUILD_TYPE=Release \
        -D FREECAD_QT_VERSION=6 \
        -W no-dev \
        -D ENABLE_DEVELOPER_TESTS=Off \
        -D Boost_USE_DEBUG_RUNTIME=FALSE \
        -D FREECAD_USE_PCL=Off \
        -D CMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -D BUILD_BIM=Off \
        -D BUILD_INSPECTION=Off \
        -D BUILD_FEM=Off \
        -D BUILD_OPENSCAD=Off \
        -D BUILD_POINTS=Off \
        -D BUILD_REVERSEENGINEERING=Off \
        -D BUILD_ROBOT=Off \
        -D BUILD_SMESH=Off \
        -D BUILD_TEST=On \
        -D BUILD_WEB=Off \
        -B "${pathBuild}" \
        -S "${pathSrc}"
#         -D HDF5_NO_FIND_PACKAGE_CONFIG_FILE=ON \
#         -D HDF5_C_COMPILER_EXECUTABLE=h5hlcc \
#         -D HDF5_CXX_COMPILER_EXECUTABLE=h5hlc++ \

    exit_status=$?
    if [[ $exit_status != 0 ]] && [[ `command -v kdialog` ]]; then
        kdialog --title "FreeCAD" --icon "error" --passivepopup "cmake error" 15
        exit
    fi
fi

echo
echo
echo
if [ "$1" == "" ]; then
    read -p "Enter cores use to compile: " coresAmount
    echo
else
    coresAmount=$1
fi


if [[ ${coresAmount} =~ ^[0-9]+$ ]]; then
    timeStart=`date +"%T"`

    if [[ `command -v kde-inhibit` ]]
        then time kde-inhibit --power cmake --build "$pathBuild" -j${coresAmount}
        else time cmake --build "$pathBuild" -j${coresAmount}
    fi

    timeFinish=`date +"%T"`
    echo
    echo 'Cores:       '$coresAmount
    echo 'Time start:  '$timeStart
    echo 'Time finish: '$timeFinish
    echo
fi

if [ `command -v kdialog` ]; then
    kdialog --title "FreeCAD" --icon "cmake" --passivepopup "Compile completed" 10
fi
