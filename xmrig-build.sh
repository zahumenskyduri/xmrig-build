#!/bin/bash

VERS="v2.1"

# Required Packages
PackagesArray=('build-essential' 'cmake' 'libuv1-dev' 'libssl-dev' 'libhwloc-dev' 'screen' 'p7zip-full' 'mc' 'htop' 'nano')

# Setup Variables
#SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
BUILD=0
DEBUG=0
STATIC=0
SCRIPT="$(readlink -f "$0")"
SCRIPTFILE="$(basename "$SCRIPT")"
SCRIPTPATH="$(dirname "$SCRIPT")"
SCRIPTNAME="$0"
ARGS=( "$@" )
BRANCH="master"

# Usage Example Function
usage_example() {
  echo -e "\e[32m=================================================="
  echo -e "==================================================\e[39m"
  echo -e "\e[33m XMRig Build Script $VERS\e[39m"
  echo
  echo -e "\e[33m by DocDrydenn\e[39m"
  echo
  echo -e "\e[32m=================================================="
  echo -e "==================================================\e[39m"
  echo
  echo " Usage:  xmrig-build [-dhs] -<0|7|8>"
  echo
  echo "    -0 | 0 | <blank>      - x86-64"
  echo
  echo "    -s | s                - Build Static"
  echo
  echo "    -h | h                - Display (this) Usage Output"
  echo "    -d | d                - Enable Debug Output"
  echo
  exit 0
}

# Flag Processing Function
flags() {
  ([ "$1" = "-h" ] || [ "$1" = "h" ]) && usage_example
  ([ "$2" = "-h" ] || [ "$2" = "h" ]) && usage_example
  ([ "$3" = "-h" ] || [ "$3" = "h" ]) && usage_example
  ([ "$4" = "-h" ] || [ "$4" = "h" ]) && usage_example

  ([ "$1" = "d" ] || [ "$1" = "-d" ]) && DEBUG=1
  ([ "$2" = "d" ] || [ "$2" = "-d" ]) && DEBUG=1
  ([ "$3" = "d" ] || [ "$3" = "-d" ]) && DEBUG=1

  ([ "$1" = "-s" ] || [ "$1" = "s" ]) && STATIC=1
  ([ "$2" = "-s" ] || [ "$2" = "s" ]) && STATIC=1
  ([ "$3" = "-s" ] || [ "$3" = "s" ]) && STATIC=1

}

# Script Update Function
self_update() {
  echo -e "\e[33mStatus:\e[39m"
  cd "$SCRIPTPATH"
  timeout 1s git fetch --quiet
  timeout 1s git diff --quiet --exit-code "origin/$BRANCH" "$SCRIPTFILE"
  [ $? -eq 1 ] && {
    echo -e "\e[31m  ✗ Version: Mismatched.\e[39m"
    echo
    echo -e "\e[33mFetching Update:\e[39m"
    if [ -n "$(git status --porcelain)" ];  # opposite is -z
    then
      git stash push -m 'local changes stashed before self update' --quiet
    fi
    git pull --force --quiet
    git checkout $BRANCH --quiet
    git pull --force --quiet
    echo -e "\e[33m  ✓ Update: Complete.\e[39m"
    echo
    echo -e "\e[33mLaunching New Version. Standby...\e[39m"
    sleep 3
    cd - > /dev/null  # return to original working dir
    exec "$SCRIPTNAME" "${ARGS[@]}"

    # Now exit this old instance
    exit 1
    }
  echo -e "\e[33m  ✓ Version: Current.\e[39m"
  echo
}

# Package Check/Install Function
packages() {
  install_pkgs=" "
  for keys in "${!PackagesArray[@]}"; do
    REQUIRED_PKG=${PackagesArray[$keys]}
    PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
    if [ "" = "$PKG_OK" ]; then
      echo -e "\e[31m  ✗ $REQUIRED_PKG: Not Found.\e[39m"
      install_pkgs+=" $REQUIRED_PKG"
    else
      echo -e "\e[33m  ✓ $REQUIRED_PKG: Found.\e[39m"
    fi
  done
  if [ " " != "$install_pkgs" ]; then
    echo
    echo -e "\e[33mInstalling Packages:\e[39m"
    if [ $DEBUG -eq 1 ]; then
      apt --dry-run -y install $install_pkgs
    else
      apt install -y $install_pkgs
    fi
  fi
}

# Error Trapping with Cleanup
errexit() {
  # Draw 5 lines of + and message
  for i in {1..5}; do echo "+"; done
  echo -e "\e[91mError raised! Cleaning Up and Exiting.\e[39m"

  # Remove _source directory if found.
  if [ -d "$SCRIPTPATH/_source" ]; then rm -r $SCRIPTPATH/_source; fi

  # Remove xmrig directory if found.
  if [ -d "$SCRIPTPATH/xmrig" ]; then rm -r $SCRIPTPATH/xmrig; fi

  # Dirty Exit
  exit 1
}

# Phase Header
phaseheader() {
  echo
  echo -e "\e[32m=======================================\e[39m"
  echo -e "\e[35m- $1..."
  echo -e "\e[32m=======================================\e[39m"
}

# Phase Footer
phasefooter() {
  echo -e "\e[32m=======================================\e[39m"
  echo -e "\e[35m $1 Completed"
  echo -e "\e[32m=======================================\e[39m"
  echo
}

# Intro/Outro Header
inoutheader() {
  echo -e "\e[32m=================================================="
  echo -e "==================================================\e[39m"
  echo -e "\e[33m XMRig Build Script $VERS\e[39m"

  [ $BUILD -eq 0 ] && echo -ne "\e[33m for x86-64\e[39m" && [ $STATIC -eq 1 ] && echo -e "\e[33m (static)\e[39m"

  echo
  echo -e "\e[33m by DocDrydenn\e[39m"
  echo

  if [[ "$DEBUG" = "1" ]]; then echo -e "\e[5m\e[96m++ DEBUG ENABLED - SIMULATION ONLY ++\e[39m\e[0m"; echo; fi
}

# Intro/Outro Footer
inoutfooter() {
  echo -e "\e[32m=================================================="
  echo -e "==================================================\e[39m"
  echo
}


# Flag Check
flags $1 $2 $3 $4

# Error Trap
trap 'errexit' ERR

# Opening Intro
clear
inoutheader
inoutfooter


#===========================================================================================================================================
### Start Phase 7
PHASE="Script_Self-Update"
phaseheader $PHASE
#===========================================================================================================================================
self_update

### End Phase 7
phasefooter $PHASE

#===========================================================================================================================================
### Start Phase 6
PHASE="Dependancies"
phaseheader $PHASE
#===========================================================================================================================================
if [ $DEBUG -eq 1 ]; then
  echo -e "\e[96m++ $PHASE - apt update\e[39m"
else
  apt update
fi
echo
packages

### End Phase 6
phasefooter $PHASE

#===========================================================================================================================================
### Start Phase 5
PHASE="Backup"
phaseheader $PHASE
#===========================================================================================================================================
if [ -d "$SCRIPTPATH/xmrig" ]
then
  if [ -f "$SCRIPTPATH/xmrig/xmrig-build.7z.bak" ]
  then
    # Remove last backup archive
    if [ $DEBUG -eq 1 ]; then
      echo -e "\e[96m++ $PHASE - rm $SCRIPTPATH/xmrig/xmrig-build.7z.bak\e[39m"
    else
      rm $SCRIPTPATH/xmrig/xmrig-build.7z.bak
    fi
  else
    echo -e "\e[33mxmrig-build.7z.bak doesn't exist - Skipping...\e[39m"
  fi
  if [ -f "$SCRIPTPATH/xmrig/xmrig.bak" ]
  then
    # Remove last backup binary
    if [ $DEBUG -eq 1 ]; then
      echo -e "\e[96m++ $PHASE - rm $SCRIPTPATH/xmrig/xmrig.bak\e[39m"
    else
      rm $SCRIPTPATH/xmrig/xmrig.bak
    fi
  else
    echo -e "\e[33mxmrig.bak doesn't exist - Skipping...\e[39m"
  fi
  if [ -f "$SCRIPTPATH/xmrig/xmrig-build.7z" ]
  then
    # Backup last archive
    if [ $DEBUG -eq 1 ]; then
      echo -e "\e[96m++ $PHASE - mv $SCRIPTPATH/xmrig/xmrig-build.7z $SCRIPTPATH/xmrig/xmrig-build.7z.bak\e[39m"
    else
      mv $SCRIPTPATH/xmrig/xmrig-build.7z $SCRIPTPATH/xmrig/xmrig-build.7z.bak
    fi
  else
    echo -e "\e[33mxmrig-build.7z doesn't exist - Skipping...\e[39m"
  fi
  if [ -f "$SCRIPTPATH/xmrig/xmrig" ]
  then
    # Backup last binary
    if [ $DEBUG -eq 1 ]; then
      echo -e "\e[96m++ $PHASE - mv $SCRIPTPATH/xmrig/xmrig $SCRIPTPATH/xmrig/xmrig.bak\e[39m"
    else
      mv $SCRIPTPATH/xmrig/xmrig $SCRIPTPATH/xmrig/xmrig.bak
    fi
  else
    echo -e "\e[33mxmrig doesn't exist - Skipping Backup...\e[39m"
  fi
else
  # Make xmrig folder if it doesn't exist
  if [ $DEBUG -eq 1 ]; then
    echo -e "\e[96m++ $PHASE - mkdir -p $SCRIPTPATH/xmrig\e[39m"
  else
    mkdir -p $SCRIPTPATH/xmrig
  fi
fi

### End Phase 5
phasefooter $PHASE

#===========================================================================================================================================
### Start Phase 4
PHASE="Setup"
phaseheader $PHASE
#===========================================================================================================================================

# If a _source directory is found, remove it.
if [ -d "$SCRIPTPATH/_source" ]
then
  if [ $DEBUG -eq 1 ]; then
    echo -e "\e[96m++ $PHASE - rm -r $SCRIPTPATH/_source\e[39m"
  else
    rm -r $SCRIPTPATH/_source
  fi
fi

# Make new source folder
if [ $DEBUG -eq 1 ]; then
  echo -e "\e[96m++ $PHASE - mkdir $SCRIPTPATH/_source\e[39m"
else
  mkdir $SCRIPTPATH/_source
fi

# Change working dir to source folder
if [ $DEBUG -eq 1 ]; then
  echo -e "\e[96m++ $PHASE - cd $SCRIPTPATH/_source\e[39m"
else
  cd $SCRIPTPATH/_source
fi

# Clone XMRig from github into source folder
if [ $DEBUG -eq 1 ]; then
  echo -e "\e[96m++ $PHASE - git clone https://github.com/xmrig/xmrig.git\e[39m"
else
  git clone https://github.com/xmrig/xmrig.git
fi

# Change working dir to clone - Create build folder
if [ $DEBUG -eq 1 ]; then
  echo -e "\e[96m++ $PHASE - cd xmrig && mkdir build\e[39m"
else
  cd xmrig && mkdir build
fi

# Building STATIC requires dependancies to be built via provided xmrig script.
if [ $STATIC -eq 1 ]
then
  if [ $DEBUG -eq 1 ]; then
    echo -e "\e[96m++ $PHASE - STATIC - cd scripts && ./build_deps.sh and cd ..\e[39m"
  else
    cd scripts && ./build_deps.sh
    cd ..
  fi
fi

# Change to build directory
if [ $DEBUG -eq 1 ]; then
  echo -e "\e[96m++ $PHASE - cd build\e[39m"
else
  cd build
fi

### End Phase 4
phasefooter $PHASE

#===========================================================================================================================================
### Start Phase 3
PHASE="Compiling/Building"
phaseheader $PHASE
#===========================================================================================================================================
# Setup build enviroment
if [ $STATIC -eq 1 ]
then
  [ $DEBUG -eq 1 ] && [ $BUILD -eq 7 ] && echo -e "\e[96m++ $PHASE - cmake .. -DCMAKE_BUILD_TYPE=Release -DARM_TARGET=7 -DWITH_OPENCL=OFF -DWITH_CUDA=OFF -DWITH_HWLOC=OFF -DWITH_ASM=OFF -DXMRIG_DEPS=scripts/deps\e[39m"
  [ $DEBUG -eq 0 ] && [ $BUILD -eq 7 ] && cmake .. -DCMAKE_BUILD_TYPE=Release -DARM_TARGET=7 -DWITH_OPENCL=OFF -DWITH_CUDA=OFF -DWITH_HWLOC=OFF -DWITH_ASM=OFF -DXMRIG_DEPS=scripts/deps
  [ $DEBUG -eq 1 ] && [ $BUILD -eq 8 ] && echo -e "\e[96m++ $PHASE - cmake .. -DCMAKE_BUILD_TYPE=Release -DARM_TARGET=7 -DWITH_OPENCL=OFF -DWITH_CUDA=OFF -DWITH_HWLOC=OFF -DWITH_ASM=OFF -DXMRIG_DEPS=scripts/deps\e[39m"
  [ $DEBUG -eq 0 ] && [ $BUILD -eq 8 ] && cmake .. -DCMAKE_BUILD_TYPE=Release -DARM_TARGET=8 -DWITH_OPENCL=OFF -DWITH_CUDA=OFF -DWITH_HWLOC=OFF -DWITH_ASM=OFF -DXMRIG_DEPS=scripts/deps
  [ $DEBUG -eq 1 ] && [ $BUILD -eq 0 ] && echo -e "\e[96m++ $PHASE - cmake .. -DCMAKE_BUILD_TYPE=Release -DXMRIG_DEPS=scripts/deps\e[39m"
  [ $DEBUG -eq 0 ] && [ $BUILD -eq 0 ] && cmake .. -DCMAKE_BUILD_TYPE=Release -DXMRIG_DEPS=scripts/deps
else
  [ $DEBUG -eq 1 ] && [ $BUILD -eq 7 ] && echo -e "\e[96m++ $PHASE - cmake .. -DCMAKE_BUILD_TYPE=Release -DARM_TARGET=7 -DWITH_OPENCL=OFF -DWITH_CUDA=OFF -DWITH_HWLOC=OFF -DWITH_ASM=OFF\e[39m"
  [ $DEBUG -eq 0 ] && [ $BUILD -eq 7 ] && cmake .. -DCMAKE_BUILD_TYPE=Release -DARM_TARGET=7 -DWITH_OPENCL=OFF -DWITH_CUDA=OFF -DWITH_HWLOC=OFF -DWITH_ASM=OFF
  [ $DEBUG -eq 1 ] && [ $BUILD -eq 8 ] && echo -e "\e[96m++ $PHASE - cmake .. -DCMAKE_BUILD_TYPE=Release -DARM_TARGET=7 -DWITH_OPENCL=OFF -DWITH_CUDA=OFF -DWITH_HWLOC=OFF -DWITH_ASM=OFF\e[39m"
  [ $DEBUG -eq 0 ] && [ $BUILD -eq 8 ] && cmake .. -DCMAKE_BUILD_TYPE=Release -DARM_TARGET=8 -DWITH_OPENCL=OFF -DWITH_CUDA=OFF -DWITH_HWLOC=OFF -DWITH_ASM=OFF
  [ $DEBUG -eq 1 ] && [ $BUILD -eq 0 ] && echo -e "\e[96m++ $PHASE - cmake .. -DCMAKE_BUILD_TYPE=Release\e[39m"
  [ $DEBUG -eq 0 ] && [ $BUILD -eq 0 ] && cmake .. -DCMAKE_BUILD_TYPE=Release
fi

# Bypass make process if debug is enabled.
if [ $DEBUG -eq 1 ]; then
  echo -e "\e[96m++ $PHASE - make\e[39m"
  #touch xmrig
else
  make
fi

# End Phase 3
phasefooter $PHASE

#===========================================================================================================================================
### Start Phase 2
PHASE="Compressing/Moving"
phaseheader $PHASE
#===========================================================================================================================================
# Compress built xmrig into archive
if [ $DEBUG -eq 1 ]; then
  echo -e "\e[96m++ $PHASE - 7z a xmrig-build.7z $SCRIPTPATH/xmrig\e[39m"
else
  7z a xmrig-build.7z $SCRIPTPATH/xmrig
fi

# Copy archive to xmrig folder
if [ $DEBUG -eq 1 ]; then
  echo -e "\e[96m++ $PHASE - cp xmrig-build.7z $SCRIPTPATH/xmrig/xmrig-build.7z\e[39m"
else
  cp xmrig-build.7z $SCRIPTPATH/xmrig/xmrig-build.7z
fi

# Copy built xmrig to xmrig folder
if [ $DEBUG -eq 1 ]; then
  echo -e "\e[96m++ $PHASE - cp $SCRIPTPATH/_source/xmrig/build/xmrig $SCRIPTPATH/xmrig/xmrig\e[39m"
else
  cp $SCRIPTPATH/_source/xmrig/build/xmrig $SCRIPTPATH/xmrig/xmrig
fi

# End Phase 2
phasefooter $PHASE

#===========================================================================================================================================
# Start Phase 1
PHASE="Cleanup"
phaseheader $PHASE
#===========================================================================================================================================

# Change working dir back to root
if [ $DEBUG -eq 1 ]; then
  echo -e "\e[96m++ $PHASE - cd $SCRIPTPATH\e[39m"
else
  cd $SCRIPTPATH
fi

# Remove source folder
if [ $DEBUG -eq 1 ]; then
  echo -e "\e[96m++ $PHASE - rm -r _source\e[39m"
else
  rm -r _source
fi

# Create start-example.sh
if [ ! -f "$SCRIPTPATH/xmrig/start-example.sh" ]; then
  if [ $DEBUG -eq 1 ]; then
    echo -e "\e[96m++ $PHASE - cat > $SCRIPTPATH/xmrig/start-example.sh <<EOF\e[39m"
  else
    cat > $SCRIPTPATH/xmrig/start-example.sh <<EOF
#! /bin/bash

screen -wipe
screen -dm $SCRIPTPATH/xmrig/xmrig -o <pool_IP>:<pool_port> -l /var/log/xmrig-cpu.log --donate-level 1 --rig-id <rig_name> -k --verbose
screen -r
EOF

    # Make start-example.sh executable
    if [ $DEBUG -eq 1 ]; then
      echo -e "\e[96m++ $PHASE - chmod +x $SCRIPTPATH/xmrig/start-example.sh\e[39m"
    else
      chmod +x $SCRIPTPATH/xmrig/start-example.sh
    fi
  fi
fi

# End Phase 1
phasefooter $PHASE

#===========================================================================================================================================
# Close Out
inoutheader
echo -e "\e[33m Folder Location: $SCRIPTPATH/xmrig/\e[39m"
echo -e "\e[33m Bin: $SCRIPTPATH/xmrig/xmrig\e[39m"
echo -e "\e[33m Example Start Script: $SCRIPTPATH/xmrig/start-example.sh\e[39m"
echo
inoutfooter

# Clean exit of script
exit 0
