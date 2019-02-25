#!/bin/bash

# Copyright (C) 2012-2016 Open Source Robotics Foundation
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Description:
# This script installs gazebo onto an Ubuntu system.

set -e

BASEDIR=$(realpath $(dirname "$0"))
EXESRC=$(realpath $BASEDIR/../test_objects)
codename=`lsb_release -sc`
OPT_DIR=${HOME}/opt
YARP_DIR=${OPT_DIR}/yarp
GAZEBO_DIR=${OPT_DIR}/icub-gazebo
GAZEBO_YARP=${OPT_DIR}/gazebo-yarp-plugins
ICUB_SRC=${OPT_DIR}/icub_src
ICUB_MAIN=${OPT_DIR}/icub

CURR_DIR=$(pwd)


bash_cmd()
{
    
    LEN=150
    PKG=$1
    STR=$2
    STRLEN=${#STR}
    LABEL="# --- $PKG ---"
    LABLEN=${#LABEL}
    SPACES=$((LEN - STRLEN - LABLEN))
    

    echo "$STR$(printf "% ${SPACES}s")$LABEL" >> ${HOME}/.bashrc
}

## UTILITIES AND DEPENDENCIES
sudo apt-get -y install libeigen3-dev libitpp-dev libboost-dev imagemagick libtinyxml-dev mercurial cmake build-essential coinor-libipopt-dev screen libjansson-dev
sudo apt-get install -y libace-dev libedit-dev cmake-curses-gui swig python2.7-dev
sudo apt-get install -y qtbase5-dev qtdeclarative5-dev qtmultimedia5-dev \
	qtdeclarative5-qtquick2-plugin qtdeclarative5-window-plugin \
	qtdeclarative5-qtmultimedia-plugin qtdeclarative5-controls-plugin \
	qtdeclarative5-dialogs-plugin libqt5svg5
sudo apt-get install -y default-jdk

# Make sure we are running a valid Ubuntu distribution
if [[ $(lsb_release -si) != "Ubuntu" ]]; then
i    echo "This script will only work on Ubuntu"
    exit 0
fi

if ! [[ -d ${OPT_DIR} ]]; then
    mkdir ${OPT_DIR}
fi



## OPENCV
echo -e "\n\n\n"
echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"
echo "Adding OpenCV3.4.1..."
if [[ -z "$(ldconfig -p| grep opencv| grep 3.4)" ]]; then

    sudo apt-get -y install qt5-default

    cd /tmp
    rm -fr opencv*
    git clone https://github.com/opencv/opencv.git
    cd opencv
    git checkout 3.4.1
    mkdir build 
    cd build
    cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local \
        -D WITH_TBB=ON -D WITH_V4L=ON -D WITH_QT=ON -D INSTALL_C_EXAMPLES=ON \
        -D INSTALL_PYTHON_EXAMPLES=ON -D WITH_OPENGL=ON .. 
    make -j8 
    sudo make install

    sudo /bin/bash -c 'echo "/usr/local/lib" > /etc/ld.so.conf.d/opencv.conf'
    sudo ldconfig
    echo "OpenCV3.4.1 added"

else
    echo "OpenCV3.4.1 already installed"
fi
source ${HOME}/.bashrc 

## YARP
echo -e "\n\n\n"
echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"
echo "Adding YARP..."
if [[ ! -d ${YARP_DIR} ]]; then

    echo "Clone, compile and install yarp"

    if [[ "$(dpkg -l | grep yarp)" ]]; then
        sudo apt --yes purge yarp
    fi

    rm -fr /tmp/yarp
    git clone https://github.com/robotology/yarp.git /tmp/yarp
    cd /tmp/yarp
    git checkout v3.1.0
    mkdir build
    cd build
    cmake -DCMAKE_INSTALL_PREFIX=${YARP_DIR} \
        -DCREATE_GUIS:BOOL=ON \
        -DYARP_COMPILE_BINDINGS:BOOL=ON \
        -DCREATE_JAVA:BOOL=ON .. \
        -DCREATE_PYTHON:BOOL=ON ..
    make install
    sudo ldconfig
    sed -i "/YARP/d" ${HOME}/.bashrc  
    echo "added YARP"
else
    echo "YARP already installed"
fi
 

YARPPYTHONPATH=$(find  ~/opt/yarp -type d | grep "python"|grep "\-packages"|head -1)  
export YARP_DIR=${YARP_DIR}
export YARP_DATA_DIRS=${YARP_DATA_DIRS}:${YARP_DIR}
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${YARP_DIR}/lib
export PYTHONPATH=${PYTHONPATH}:$YARPPYTHONPATH
bash_cmd YARP "# YARP ---------------------------------------------------------------------------"
bash_cmd YARP ""
bash_cmd YARP "export PATH=\${PATH}:${YARP_DIR}/bin                                              " 
bash_cmd YARP "export YARP_DIR=${YARP_DIR}                                                       "
bash_cmd YARP "export YARP_DATA_DIRS=\${YARP_DATA_DIRS}:${YARP_DIR}                              "
bash_cmd YARP "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:${YARP_DIR}/lib                        "
bash_cmd YARP "export PYTHONPATH=\${PYTHONPATH}:$YARPPYTHONPATH                                  "
bash_cmd YARP ""
bash_cmd YARP "# YARP ---------------------------------------------------------------------------"


## GAZEBO
echo -e "\n\n\n"
echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"
echo "Adding Gazebo..."
if [[ -z "$(dpkg -l | grep gazebo7)" ]]; then
    # Add the repository
    echo "Adding the gazebo repository"
    if [[ ! -e /etc/apt/sources.list.d/gazebo-stable.list ]]; then
        sudo sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable '$codename' main" > /etc/apt/sources.list.d/gazebo-stable.list'
    fi

    # Download the OSRF keys
    has_key=$(sudo apt-key list | grep "OSRF Repository" || true)

    echo "Downloading keys"
    if [[ -z "$has_key" ]]; then
        wget --quiet http://packages.osrfoundation.org/gazebo.key -O - | sudo apt-key add -
    fi


    # Update apt
    echo "Retrieving packages"
    sudo apt-get update -qq
    echo "OK"

    # Install gazebo
    if [[ -z "$(dpkg -l| grep "\<gazebo7\>")" ]]; then
        echo "Installing Gazebo"
        sudo apt-get --yes --force-yes install gazebo7 libgazebo7-dev

        echo "Gazebo added"
    fi
else
    echo "Gazebo already installed"
fi

# ICUB-MAIN
echo -e "\n\n\n"
echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"
echo "Adding icub..."
if [[ ! -d ${ICUB_MAIN} && ! -d ${ICUB_SRC} ]]; then

    rm -fr  $ICUB_SRC
    mkdir -p $ICUB_SRC
    cd $ICUB_SRC
    git clone https://github.com/robotology/icub-main .
    mkdir build 
    cd build 
    cmake ../ \
        -DENABLE_icubmod_cartesiancontrollerclient:BOOL=ON \
        -DENABLE_icubmod_cartesiancontrollerserver:BOOL=ON \
        -DENABLE_icubmod_gazecontrollerclient:BOOL=ON \
        -DICUB_USE_IPOPT:BOOL=TRUE \
        -DCMAKE_INSTALL_PREFIX=${ICUB_MAIN}
    make -j8 -l8
    make install

    # set position control for left and right arm
    for f in ${ICUB_MAIN}/share/iCub/contexts/simCartesianControl/cartesian/*_arm_*xml
    do
        sed -i -e "s/\(PositionControl\">\)off/\1on/" $f
    done

    echo "icub added"

else
    echo "icub already installed"
fi

export PATH=${PATH}:${ICUB_MAIN}/bin 
export YARP_DATA_DIRS=${YARP_DATA_DIRS}:${ICUB_MAIN}/share/iCub/:${ICUB_MAIN}/share/iCub/plugins/
export ICUB_DIR=${ICUB_MAIN}

sed -i "/ICUB_MAIN/d" ${HOME}/.bashrc    
bash_cmd ICUB_MAIN "# ICUB_MAIN ----------------------------------------------------------------------"
bash_cmd ICUB_MAIN ""
bash_cmd ICUB_MAIN "export PATH=\${PATH}:${ICUB_MAIN}/bin                                                                " 
bash_cmd ICUB_MAIN "export YARP_DATA_DIRS=\${YARP_DATA_DIRS}:${ICUB_MAIN}/share/iCub/:${ICUB_MAIN}/share/iCub/plugins/   "
bash_cmd ICUB_MAIN "export ICUB_DIR=${ICUB_MAIN}                                                                         "
bash_cmd ICUB_MAIN ""
bash_cmd ICUB_MAIN "# ICUB_MAIN ----------------------------------------------------------------------"
    

# GAZEBO ICUB
echo -e "\n\n\n"
echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"
echo "Adding Icub models for gazebo..."
# need this to patch the sdf file
if [[ ! -d $GAZEBO_DIR ]]; then  

    cd /tmp
    rm -fr icub*
    git clone https://github.com/xEnVrE/icub-gazebo.git g_icub_forked
    cd g_icub_forked
    git checkout 9268035 
    git diff  HEAD@{1}  icub_with_hands/icub_with_hands.sdf > /tmp/gazebo_icub_sdf.patch

    cd ${OPT_DIR}
    git clone https://github.com/robotology/icub-gazebo.git 
    cd icub-gazebo
    git apply /tmp/gazebo_icub_sdf.patch

    


    cp -r $BASEDIR/icub-gazebo $OPT_DIR/
    echo "Gazebo icub models added"

else
    echo "Gazebo icub models already installed"
fi

if [[ -z "$GAZEBO_MODEL_PATH" ]]; then
	export GAZEBO_MODEL_PATH=${GAZEBO_DIR}
else
    export GAZEBO_MODEL_PATH=${GAZEBO_MODEL_PATH}:${GAZEBO_DIR}
fi
sed -i "/GAZEBO_ICUB/d" ${HOME}/.bashrc    
bash_cmd GAZEBO_ICUB "# GAZEBO_ICUB ----------------------------------------------------------------------"
bash_cmd GAZEBO_ICUB "" 
bash_cmd GAZEBO_ICUB "if [[ -z \"\$GAZEBO_MODEL_PATH\" ]]; then"
bash_cmd GAZEBO_ICUB "    export GAZEBO_MODEL_PATH=${GAZEBO_DIR}"
bash_cmd GAZEBO_ICUB "else"
bash_cmd GAZEBO_ICUB "    export GAZEBO_MODEL_PATH=\${GAZEBO_MODEL_PATH}:${GAZEBO_DIR}"
bash_cmd GAZEBO_ICUB "fi"
bash_cmd GAZEBO_ICUB "" 
bash_cmd GAZEBO_ICUB "# GAZEBO_ICUB ----------------------------------------------------------------------"


## GAZEBO-YARP PLUGIN
echo -e "\n\n\n"
echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"
echo "Adding gazebo-yarp-plugins..."
if [[ ! -d ${GAZEBO_YARP} ]]; then
    cd /tmp
    rm -fr gazebo*
    git clone https://github.com/GOAL-Robots/gazebo-yarp-plugins-gaze-mass.git
    #git clone https://github.com/robotology/gazebo-yarp-plugins.git
    cd gazebo-yarp-plugins-gaze-mass
    mkdir build 
    cd build
    cmake .. -DCMAKE_INSTALL_PREFIX=${GAZEBO_YARP} -DALLOW_IDL_GENERATION="ON"
    make -j8 -l8
    make install

    echo "gazebo-yarp-plugins added"

else
    echo "gazebo-yarp-plugins already installed"
fi

export GAZEBO_PLUGIN_PATH=${GAZEBO_PLUGIN_PATH}:${GAZEBO_YARP}/lib
sed -i "/GAZEBO_TARP_PLUGIN/d" ${HOME}/.bashrc    
bash_cmd GAZEBO_YARP_PLUGIN "# GAZEBO_YARP_PLUGIN ----------------------------------------------------------------------"
bash_cmd GAZEBO_YARP_PLUGIN "" 
bash_cmd GAZEBO_YARP_PLUGIN "export GAZEBO_PLUGIN_PATH=\${GAZEBO_PLUGIN_PATH}:${GAZEBO_YARP}/lib" 
bash_cmd GAZEBO_YARP_PLUGIN "" 
bash_cmd GAZEBO_YARP_PLUGIN "# GAZEBO_YARP_PLUGIN ----------------------------------------------------------------------"


# GZWEB
echo -e "\n\n\n"
echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"
echo "Adding gazebo web client..."
if [[ ! -d "${OPT_DIR}/gzweb" ]]; then
    curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
    cd ${OPT_DIR}

    alias python="python2"
    wget http://nodejs.org/dist/v0.10.48/node-v0.10.48.tar.gz
    tar -xvf node-v0.10.48.tar.gz
    cd node-v0.10.48
    ./configure
    make -j 8                         
    sudo make -j8 install           
    npm install gyp
    cd ..
    unalias python

    hg clone https://bitbucket.org/osrf/gzweb
    cd gzweb
    hg up gzweb_1.3.0
    source /usr/share/gazebo/setup.sh
    ./deploy.sh -m local

    echo "gazebo web client added"
else
    echo "gazebo web client already installed"
fi

# test
echo -e "\n\n\n"
echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"
echo "build GOAL-Robot controller for testing"

BUILDEXE_DIR=${BASEDIR}/../test_build
[[ ! -z $BUILDEXE_DIR ]] && rm -fr $BUILDEXE_DIR/*
mkdir -p $BUILDEXE_DIR
cd  $BUILDEXE_DIR
cmake $EXESRC
make -j8

cd $CURR_DIR
