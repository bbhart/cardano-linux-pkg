#!/bin/bash -eu

if test -d "$2" ; then
  (cd "$2" && git checkout master && git pull --rebase)
else
  git clone "$1" "$2"
  fi
