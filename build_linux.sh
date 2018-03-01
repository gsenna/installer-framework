#!/bin/bash

set -o errexit -o nounset

# Update platform
echo "Updating platform..."

# Install p7zip for packaging archive for deployment
sudo -E apt-get -yq --no-install-suggests --no-install-recommends --force-yes install p7zip-full 

# Hold on to current directory
project_dir=$(pwd)

mkdir build
cd build
echo "Downloading QtIFW files..."
wget https://github.com/gsenna/installer-framework/releases/download/QtIFW_linux_binaries/QtIFW_linux_binaries.7z
echo "Extracting QtIFW files..."
7z x QtIFW_linux_binaries.7z &> /dev/null

# Copy installerbase to the CsoundMaintenanceTool data folder
echo "Copying installerbase to the CsoundMaintenanceTool data Folder..."
7z a installerbase_"$CSOUND_TRAVIS_INSTALLERBASE_VERSION".7z installerbase
cp installerbase.7z ../installer-repo/linux/packages/CsoundMaintenanceTool/data/

# Sed para cambiar los xml
sed "s/<Version>.*<\/Version>/<Version>$CSOUND_TRAVIS_INSTALLERBASE_VERSION<\/Version>/" installer-repo/linux/config/config.xml
sed "s/<Version>.*<\/Version>/<Version>$CSOUND_TRAVIS_INSTALLERBASE_VERSION<\/Version>/" installer-repo/linux/packages/CsoundMaintenanceTool/meta/package.xml
sed "s/<Version>.*<\/Version>/<Version>$CSOUND_TRAVIS_WINXOUND_VERSION<\/Version>/" installer-repo/linux/packages/WinXound/meta/package.xml

# Create Online Installer
echo "Creating Online Installer..."
./binarycreator -c ../installer-repo/linux/config/config.xml -p ../installer-repo/linux/packages/ -t installerbase Csound_${TRAVIS_TAG}_linux_x86_64_OnlineInstaller

# repogen

./repogen -p ../installer-repo/linux/packages/ temp-repo


echo "Done!"

exit 0

