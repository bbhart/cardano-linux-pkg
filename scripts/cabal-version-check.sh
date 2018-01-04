#!/bin/bash -eu

version=$(cabal --numeric-version)
case ${version} in
  1.24.*)
	;;
  *)
    echo "Unsupported cabal-install version : ${version}"
    exit 1
    ;;
  esac
