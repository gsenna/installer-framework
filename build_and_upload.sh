#!/bin/bash

set -o errexit -o nounset

# Update platform
echo "Updating platform..."

# Install p7zip for packaging archive for deployment
sudo -E apt-get -yq --no-install-suggests --no-install-recommends --force-yes install p7zip-full libxkbcommon-x11-0

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
mkdir -p ../installer-repo/linux/packages/CsoundMaintenanceTool/data
7z a  ../installer-repo/linux/packages/CsoundMaintenanceTool/data/installerbase_"$CSOUND_TRAVIS_INSTALLERBASE_VERSION".7z installerbase

# Sed para cambiar los xml
sed -i "s/<Version>.*<\/Version>/<Version>$CSOUND_TRAVIS_INSTALLERBASE_VERSION<\/Version>/" ../installer-repo/linux/config/config.xml
sed -i "s/<Version>.*<\/Version>/<Version>$CSOUND_TRAVIS_INSTALLERBASE_VERSION<\/Version>/" ../installer-repo/linux/packages/CsoundMaintenanceTool/meta/package.xml
sed -i "s/<Version>.*<\/Version>/<Version>$CSOUND_TRAVIS_WINXOUND_VERSION<\/Version>/" ../installer-repo/linux/packages/WinXound/meta/package.xml

# repogen
./repogen -p ../installer-repo/linux/packages/ temp-repo

# Create Online Installer
echo "Creating Online Installer..."
./binarycreator -c ../installer-repo/linux/config/config.xml -p ../installer-repo/linux/packages/ -t installerbase temp-repo/Csound_${TRAVIS_TAG}_linux_x86_64_OnlineInstaller

echo "Extracting id for the online repo"
ONLINE_REPO_ID="$(curl -s https://api.github.com/repos/gsenna/installer-framework/releases/tags/online-repo | sed -n 's/.*"id": \(.*\).*,/\1/p' | sed -n 1p)"

if [[ $ONLINE_REPO_ID == "" ]]; then
  echo "Repository not found! Creating it..."
  curl -s -X POST -H "Content-Type: application/json" "https://api.github.com/repos/gsenna/installer-framework/releases?access_token=${GH_TOKEN}" -d '{"tag_name": "online-repo", "target_commitish": "master", "name": "Online repository", "body": "This is the online repository for this project. This is probably not what you are looking for!", "draft": false, "prerelease": false}'
fi

echo "Listing assets..."
ONLINE_REPO_UPLOAD_URL="$(curl -s https://api.github.com/repos/gsenna/installer-framework/releases/${ONLINE_REPO_ID} | sed -n 's/.*upload_url": "\(.*\){?name,label}",/\1/p')"

for file in temp-repo/*/*; do
  ONLINE_REPO_ASSETS="$(curl -s https://api.github.com/repos/gsenna/installer-framework/releases/${ONLINE_REPO_ID}/assets)"
  FILENAME="${file##*/}"
  OUTPUT="$(echo ${ONLINE_REPO_ASSETS} | sed -n s/.*\(\/${FILENAME}\"\).*/\1/p)"
  if [[ "$OUTPUT" == "" ]]; then
    echo "Uploading assets... "
    curl -s --data-binary @"$file" -H "Authorization: token $GH_TOKEN" -H "Content-Type: application/x-7z-compressed" "$ONLINE_REPO_UPLOAD_URL?name=${file##*/}"
  fi
done

cd temp-repo
echo "Uploading online installer... "
curl -s --data-binary @"Csound_${TRAVIS_TAG}_linux_x86_64_OnlineInstaller" -H "Authorization: token $GH_TOKEN" -H "Content-Type: application/octet-stream" "$ONLINE_REPO_UPLOAD_URL?name=Csound_${TRAVIS_TAG}_linux_x86_64_OnlineInstaller"


echo "Done!"

  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "Travis CI"
  git clone https://${GH_TOKEN}@github.com/gsenna/installer-framework.git installer-master > /dev/null 2>&1
  cd installer-master/installer-repo/linux
  cp ../../../Updates.xml .
  git add Updates.xml
  git commit --message "Travis Linux build: $TRAVIS_BUILD_NUMBER [skip ci]"
  git push

exit 0
