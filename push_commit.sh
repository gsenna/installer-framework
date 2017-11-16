#!/bin/bash

# taken from https://gist.github.com/mitchellkrogza/a296ab5102d7e7142cc3599fca634203

head_ref=$(git rev-parse HEAD)
if [[ $? -ne 0 || ! $head_ref ]]; then
    echo "failed to get HEAD reference"
    return 1
fi

branch_ref=$(git rev-parse "$TRAVIS_BRANCH")
if [[ $? -ne 0 || ! $branch_ref ]]; then
    echo "failed to get $TRAVIS_BRANCH reference"
    return 1
fi

if [[ $head_ref != $branch_ref ]]; then
    echo "HEAD ref ($head_ref) does not match $TRAVIS_BRANCH ref ($branch_ref)"
    echo "someone may have pushed new commits before this build cloned the repo"
    return 0
fi

if ! git checkout "$TRAVIS_BRANCH"; then
    echo "failed to checkout $TRAVIS_BRANCH"
    return 1
fi

echo  "THIS IS THE UPDATES FILE" > Updates.xml

if ! git add --all Updates.xml; then
     echo "failed to add modified files to git index"
     return 1
fi

    # make Travis CI skip this build
if ! git commit -m "Travis CI update Updates.xml [ci skip]"; then
      echo "failed to commit updates"
      return 1
fi

# add to your .travis.yml: `branches\n  except:\n  - "/\\+travis\\d+$/"\n`
#local git_tag=SOME_TAG_TRAVIS_WILL_NOT_BUILD+travis$TRAVIS_BUILD_NUMBER
#if ! git tag "$git_tag" -m "Generated tag from Travis CI build $TRAVIS_BUILD_NUMBER"; then
#    echo "failed to create git tag: $git_tag"
#    return 1
#fi

#remote=origin
#if [[ $GITHUB_TOKEN ]]; then
#    remote=https://$GITHUB_TOKEN@github.com/$TRAVIS_REPO_SLUG
#fi

#if [[ $TRAVIS_BRANCH != master ]]; then
#    echo "not pushing updates to branch $TRAVIS_BRANCH"
#    return 0
#fi

if ! git push origin HEAD:master ; then
    echo "failed to push git changes"
    exit 1
fi

