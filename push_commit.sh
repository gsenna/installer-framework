#!/bin/bash

setup_git() {
  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "Travis CI"
}

commit_website_files() {
  git checkout master
  echo "sdfsdfs" > Updates.xml
  git add Updates.xml
  git commit --message "Travis build: $TRAVIS_BUILD_NUMBER [skip ci]"
}

upload_files() {
  git remote set-url origin gsenna@github.com:gsenna/installer-framework.git > /dev/null 2>&1
  git push --quiet origin HEAD:master
}

setup_git
commit_website_files
upload_files