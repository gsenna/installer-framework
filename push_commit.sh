#!/bin/bash

setup_git() {
  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "Travis CI"
}

commit_website_files() {
  git clone https://${GH_TOKEN}@github.com/gsenna/installer-framework.git installer-master > /dev/null 2>&1
  cd installer-master
  echo "sdfsdfs" > Updates.xml
  git add Updates.xml
  git commit --message "Travis build: $TRAVIS_BUILD_NUMBER [skip ci]"
}

upload_files() {
  git push
}

setup_git
commit_website_files
upload_files
