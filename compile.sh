#!/bin/bash

pathBuild="/home/user/projects/FreeCAD_build"
pathSource="/home/user/projects/FreeCAD_src"

arg2="$2"

if [ "$arg2" == "" ]; then
    echo
    read -p "Need to reconfigure? (y/N): " reconf
fi

if [[ "$arg2" == "configure" ]] || [[ "$reconf" == "y" ]] || [[ "$reconf" == "Y" ]]; then
    echo
    echo "cmake configure"
    echo

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
        -B "$pathBuild" \
        -S "$pathSource"
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
    kdialog --title "FreeCAD" --icon "cmake" --passivepopup "Compile completed" 15
fi
