#!/bin/bash -eu

version=$(ghc --numeric-version)
case ${version} in
  8.0.2)
	;;
  *)
    echo "Unsupported GHC version : ${version}"
    exit 1
    ;;
  esac
