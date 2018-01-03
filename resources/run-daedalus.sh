#!/bin/bash

cd $(dirname $0)

if test ! -f tls/ca/ca.crt ; then
  echo "SSL certificates not generated yet."
  echo "You need to cd to $(pwd) and run 'bash build-certificates-unix.sh'."
  exit 1
  fi

CFGDIR=${HOME}/.config/Daedalus

mkdir -p ${CFGDIR}/Secrets-1.0
mkdir -p ${CFGDIR}/Logs/pub

./cardano-launcher \
  --node "./cardano-node" \
  --node-log-path "${CFGDIR}/Logs/cardano-node.log" \
  --db-path "${CFGDIR}/DB-1.0" \
  --wallet "./Daedalus-linux-x64/Daedalus" \
  --launcher-logs-prefix "${CFGDIR}/Logs/pub/" \
  --updater "/usr/bin/open" -u -FW --update-archive  "${CFGDIR}/installer.pkg" \
  --configuration-file "./configuration.yaml" \
  --configuration-key "mainnet_wallet_macos64" \
  --node-timeout 30  -n \
  --report-server -n http://report-server.cardano-mainnet.iohk.io:8080 -n \
  --log-config -n log-config-prod.yaml -n \
  --update-latest-path -n "${CFGDIR}/installer.pkg" \
  -n --keyfile -n "${CFGDIR}/Secrets-1.0/secret.key" -n \
  --logs-prefix -n "${CFGDIR}/Logs" -n \
  --db-path -n "${CFGDIR}/DB-1.0" -n \
  --wallet-db-path -n "${CFGDIR}/Wallet-1.0" -n \
  --update-server -n http://update.cardano-mainnet.iohk.io -n \
  --update-with-package -n --no-ntp -n \
  --tlscert -n "./tls/server/server.crt" -n \
  --tlskey -n "./tls/server/server.key" -n \
  --tlsca -n "./tls/ca/ca.crt" -n \
  --topology -n "./wallet-topology.yaml"
