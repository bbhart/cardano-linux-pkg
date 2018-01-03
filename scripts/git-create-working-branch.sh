#!/bin/bash -eu

branch=${1:-""}

if test -z "${branch}" ; then
  echo "Usage: $0 <branch name or tag or commit hash>"
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

git checkout ${branch} -b working-branch
