#!/bin/bash

set -o errexit -o nounset

# Update platform
echo "Updating platform..."

# Install p7zip for packaging archive for deployment
sudo -E apt-get -yq --no-install-suggests --no-install-recommends --force-yes install p7zip-full libxkbcommon-x11-0 xmlstarlet


# Hold on to current directory
project_dir=$(pwd)

MASTER_OR_PREVIEW=$(git ls-remote origin | sed -n 's-'"$TRAVIS_COMMIT"'.*refs/heads/\(master\|preview\)$-\1-p')

mkdir csound
cd csound
sudo -E  apt-get -yq build-dep csound
sudo -E  apt-get -yq install cmake
git clone https://github.com/csound/csound.git csound-clone
mkdir cs6make
cd cs6make
cmake -DCMAKE_INSTALL_PREFIX:PATH=/opt/Csound6 ../csound-clone
make
sudo make install


cd "$project_dir"
mkdir build
cd build
echo "Downloading QtIFW files..."
wget https://dl.bintray.com/gsenna/installer-framework/travis_linux/QtIFW/QtIFW_linux_binaries.7z
echo "Extracting QtIFW files..."
7z x QtIFW_linux_binaries.7z &> /dev/null

if [[ "${MASTER_OR_PREVIEW}" == "master" ]]; then
  # Copy installerbase to the CsoundMaintenanceTool data folder
  echo "Copying installerbase to the CsoundMaintenanceTool data Folder..."
  mkdir -p ../installer-repo/travis_linux/master/packages/CsoundMaintenanceTool/data
  cp installerbase .tempCsoundMaintenanceToolbase
  7z a  ../installer-repo/travis_linux/master/packages/CsoundMaintenanceTool/data/installerbase.7z .tempCsoundMaintenanceToolbase

  # Copy Csound6 to the CsoundCore data folder
  echo "Copying Csound to the CsoundCore.Csound data Folder..."
  mkdir -p ../installer-repo/travis_linux/master/packages/CsoundCore.Csound6/data
  cd /opt/Csound6
  7z a "$project_dir"/installer-repo/travis_linux/master/packages/CsoundCore.Csound6/data/Csound.7z .
  cd "$project_dir"/build

else
  # Copy Csound6 to the Preview data folder
  echo "Copying Csound to the Preview.Csound data Folder..."
  mkdir -p ../installer-repo/travis_linux/preview/packages/Preview.Csound6/data
  cd /opt/Csound6
  7z a "$project_dir"/installer-repo/travis_linux/preview/packages/Preview.Csound6/data/Csound.7z .
  cd "$project_dir"/build


fi


# Sed para cambiar los xml
#sed -i "s/<Version>.*<\/Version>/<Version>$CSOUND_TRAVIS_INSTALLERBASE_VERSION<\/Version>/" ../installer-repo/linux/config/config.xml
#sed -i "s/<Version>.*<\/Version>/<Version>$CSOUND_TRAVIS_INSTALLERBASE_VERSION<\/Version>/" ../installer-repo/linux/packages/CsoundMaintenanceTool/meta/package.xml
#sed -i "s/<Version>.*<\/Version>/<Version>$CSOUND_TRAVIS_WINXOUND_VERSION<\/Version>/" ../installer-repo/linux/packages/WinXound/meta/package.xml

# repogen
./repogen -p ../installer-repo/travis_linux/"${MASTER_OR_PREVIEW}"/packages/ "${MASTER_OR_PREVIEW}" 


if [[ "${MASTER_OR_PREVIEW}" == "master" ]]; then
  # Create Online Installer
  echo "Creating Online Installer..."
  mkdir Installers/
  ./binarycreator -c ../installer-repo/travis_linux/master/config/config.xml -p ../installer-repo/travis_linux/master/packages/ -t installerbase Installers/Csound_"${TRAVIS_TAG}"_linux_x86_64_OnlineInstaller
  curl -s -T Installers/Csound_${TRAVIS_TAG}_linux_x86_64_OnlineInstaller -ugsenna:${BINTRAY_TOKEN} "https://api.bintray.com/content/gsenna/installer-framework/installer-framework/1/travis_linux/Installers/Csound_${TRAVIS_TAG}_linux_x86_64_OnlineInstaller?override=1&publish=1"
fi

#echo "Extracting id for the online repo"
#ONLINE_REPO_ID="$(curl -s https://api.github.com/repos/gsenna/installer-framework/releases/tags/online-repo | sed -n 's/.*"id": \(.*\).*,/\1/p' | sed -n 1p)"

#if [[ $ONLINE_REPO_ID == "" ]]; then
#  echo "Repository not found! Creating it..."
#  curl -s -X POST -H "Content-Type: application/json" "https://api.github.com/repos/gsenna/installer-framework/releases?access_token=${GH_TOKEN}" -d '{"tag_name": "online-repo", "target_commitish": "master", "name": "Online repository", "body": "This is the online repository for this project. This is probably not what you are looking for!", "draft": false, "prerelease": false}'
#fi

#echo "Listing assets..."
#ONLINE_REPO_UPLOAD_URL="$(curl -s https://api.github.com/repos/gsenna/installer-framework/releases/${ONLINE_REPO_ID} | sed -n 's/.*upload_url": "\(.*\){?name,label}",/\1/p')"

curl -s -T "${MASTER_OR_PREVIEW}"/Updates.xml -ugsenna:${BINTRAY_TOKEN} "https://api.bintray.com/content/gsenna/installer-framework/installer-framework/1/travis_linux/${MASTER_OR_PREVIEW}/Updates.xml?override=1&publish=1"


for file in "${MASTER_OR_PREVIEW}"/*/*; do
    echo "Uploading assets... "
 #   curl -s --data-binary @"$file" -H "Authorization: token $GH_TOKEN" -H "Content-Type: application/x-7z-compressed" "$ONLINE_REPO_UPLOAD_URL?name=${file##*/}"
    curl -s -T ${file} -ugsenna:${BINTRAY_TOKEN} "https://api.bintray.com/content/gsenna/installer-framework/installer-framework/1/travis_linux/${file}?override=1&publish=1"
done


#for file in temp-repo/WinXound/*.sha1; do
#    echo "Uploading sha1... "
#    curl -s --data-binary @"$file" -H "Authorization: token $GH_TOKEN" -H "Content-Type: application/x-sha1" "$ONLINE_REPO_UPLOAD_URL?name=${file##*/}"
#done

#cd master
#echo "Uploading online installer... "
#curl -s --data-binary @"Csound_${TRAVIS_TAG}_linux_x86_64_OnlineInstaller" -H "Authorization: token $GH_TOKEN" -H "Content-Type: application/octet-stream" "$ONLINE_REPO_UPLOAD_URL?name=Csound_${TRAVIS_TAG}_linux_x86_64_OnlineInstaller"
if [[ "${MASTER_OR_PREVIEW}" == "master" ]]; then
    wget https://dl.bintray.com/gsenna/installer-framework/travis_linux/preview/Updates.xml
    xmlstarlet ed --inplace -d "//parent[PackageUpdate[contains(text(),'Preview.Csound6')]]" Updates.xml
    PREVIEW_PACKAGES_LEFT=$(xmlstarlet sel -t -c "count(//PackageUpdate)" Updates.xml)
    if [[ "$PREVIEW_PACKAGES_LEFT" < 3 ]]; then xmlstarlet ed --inplace -d "//PackageUpdate" Updates.xml; fi
    curl -s -T Updates.xml -ugsenna:${BINTRAY_TOKEN} "https://api.bintray.com/content/gsenna/installer-framework/installer-framework/1/travis_linux/preview/Updates.xml?override=1&publish=1"
fi

echo "Done!"

#  git config --global user.email "travis@travis-ci.org"
#  git config --global user.name "Travis CI"
#  git clone https://${GH_TOKEN}@github.com/gsenna/installer-framework.git installer-master > /dev/null 2>&1
#  cd installer-master/installer-repo/linux
#  cp ../../../Updates.xml .
#  git add Updates.xml
#  git commit --message "Travis Linux build: $TRAVIS_BUILD_NUMBER [skip ci]"
#  git push

exit 0
