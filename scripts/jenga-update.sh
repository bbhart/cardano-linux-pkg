#!/bin/bash -eu



if test -f $1/.jenga ; then
  (cd $1/ && jenga update)
else
  (cd $1/ && jenga init -m "$2" -d "$3")
  fi
