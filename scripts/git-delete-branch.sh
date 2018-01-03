#!/bin/bash -eu

branch=${1:-""}

if test -z "${branch}" ; then
  echo "Usage: $0 <branch name>"
  exit 1
  fi

case $(basename $(pwd)) in
  cardaono-sl) ;;
  daedalus) ;;
  *)
    echo "Error: This script should only be run in the cardano-sl and daedalus directories."
    exit 1
    ;;
  esac

# Can't delete the branch we are on, so always swicth to master.
git checkout master > /dev/null 2>&1

if test $(git branch | sed 's/.* //' | grep -c "^${branch}\$") -eq 1 ;  then
  git branch -D ${branch}
  fi
