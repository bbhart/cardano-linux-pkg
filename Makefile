
# Pre-reqisites:
#     cabal-install-1.24
#     g++
#     gcc
#     ghc-8.0.2
#     liblzma-dev
#     librocksdb-dev
#     libsnappy-dev
#     libssl-dev
#     make
#     python2.7


DATE = $(shell date)
PWD := $(shell pwd)

export HOME = $(PWD)/home

# Want the local path to come before global paths.
export PATH := $(PWD)/tools/bin:$(PATH)

export MAFIA_HOME := $(HOME)/mafia

TOOLS = tools/bin/autoexporter tools/bin/jenga tools/bin/mafia tools/bin/markdown-unlit

# 38b63f52313474f996457315cdba05e9cd78fead
CARDANO_VERSION ?= develop
DAEDALUS_VERSION ?= master

MAFIA_DROP_DEP = directory,binary-example,chat,latency

all : results/cardano-launcher results/cardano-node results/run-daedalus.sh \
		results/Daedalus-linux-x64/Daedalus
	make install-aux

purge :
	# This is a really big hammer. Use sparingly.
	rm -rf  bin/ home/ results/ source/ stamp/ tools/

purge-cardano :
	rm -rf source/cardano-sl/ stamp/cardano-source

purge-daedalus :
	rm -rf source/daedalus stamp/daedalus-source

#-------------------------------------------------------------------------------
# Daedelus related stuff.

results/run-daedalus.sh : resources/run-daedalus.sh
	mkdir -p results
	cp -f $+ $@
	chmod u+x $@

results/Daedalus-linux-x64/Daedalus : source/daedalus/release/linux-x64/Daedalus-linux-x64/Daedalus
	cp -r source/daedalus/release/linux-x64/Daedalus-linux-x64 $(shell dirname $@)

source/daedalus/release/linux-x64/Daedalus-linux-x64/Daedalus : source/daedalus/node_modules/daedalus-client-api/package.json
	(cd source/daedalus && npm run package --icon source/daedalus/installers/icons/256x256.png)

source/daedalus/node_modules/daedalus-client-api/package.json : stamp/daedalus-source stamp/daedalus-bridge tools/bin/node
	rm -rf source/daedalus/node_modules/daedalus-client-api
	(cd source/daedalus && npm link && npm install)
	cp -r source/cardano-sl/daedalus source/daedalus/node_modules/daedalus-client-api
	touch $@

stamp/daedalus-source :
	mkdir -p stamp
	scripts/git-sync-repo.sh https://github.com/input-output-hk/daedalus source/daedalus
	touch $@

#-------------------------------------------------------------------------------
# Auxillary files.

clean-aux :
	rm -f $(AUX_TARGETS)

install-aux :
	mkdir -p results
	make $(AUX_TARGETS)

AUX_TARGETS = \
	results/log-config-prod.yaml results/mainnet-genesis-dryrun-with-stakeholders.json \
	results/mainnet-genesis.json results/mainnet-staging-short-epoch-genesis.json \
	results/configuration.yaml results/build-certificates-unix.sh results/wallet-topology.yaml \
	results/ca.conf results/client.conf results/server.conf

results/log-config-prod.yaml : source/cardano-sl/log-config-prod.yaml
	cp -f $+ $@

results/mainnet-genesis-dryrun-with-stakeholders.json : source/cardano-sl/lib/mainnet-genesis-dryrun-with-stakeholders.json
	cp -f $+ $@

results/mainnet-genesis.json : source/cardano-sl/lib/mainnet-genesis.json
	cp -f $+ $@

results/mainnet-staging-short-epoch-genesis.json : source/cardano-sl/lib/mainnet-staging-short-epoch-genesis.json
	cp -f $+ $@

results/configuration.yaml : source/cardano-sl/lib/configuration.yaml
	cp -f $+ $@

results/build-certificates-unix.sh : source/daedalus/installers/build-certificates-unix.sh
	cp -f $+ $@

results/wallet-topology.yaml : source/daedalus/installers/wallet-topology.yaml
	cp -f $+ $@

results/ca.conf : source/daedalus/installers/ca.conf
	cp -f $+ $@

results/client.conf : source/daedalus/installers/client.conf
	cp -f $+ $@

results/server.conf : source/daedalus/installers/server.conf
	cp -f $+ $@

#-------------------------------------------------------------------------------
# Build cardano-launcher, cardano-node and daedalus bridge.

stamp/daedalus-bridge : tools/bin/cardano-wallet-hs2purs tools/bin/node
	(cd source/cardano-sl && cardano-wallet-hs2purs)
	(cd source/cardano-sl/daedalus && npm install)
	touch $@

tools/bin/cardano-wallet-hs2purs : source/cardano-sl/.jenga $(TOOLS)
	mkdir -p tools/bin/
	(cd source/cardano-sl/wallet && mafia build cardano-wallet-hs2purs)
	(cp -f source/cardano-sl/wallet/dist/build/cardano-wallet-hs2purs/cardano-wallet-hs2purs $@)

results/cardano-launcher : source/cardano-sl/.jenga $(TOOLS)
	scripts/ghc-version-check.sh
	(cd source/cardano-sl/tools && mafia build cardano-launcher)
	cp -f source/cardano-sl/tools/dist/build/cardano-launcher/cardano-launcher $@

results/cardano-node : source/cardano-sl/.jenga $(TOOLS)
	scripts/ghc-version-check.sh
	(cd source/cardano-sl/wallet && mafia build cardano-node)
	cp -f source/cardano-sl/wallet/dist/build/cardano-node/cardano-node $@

source/cardano-sl/.jenga : stamp/cardano-source $(TOOLS)
	(cd source/cardano-sl/ && git checkout $(CARDANO_VERSION))
	scripts/jenga-update.sh source/cardano-sl/ submods ${MAFIA_DROP_DEP}
	(cd source/cardano-sl/ && git add .gitmodules submods && git commit -m "Add submodules" -- . )
	touch $@

stamp/cardano-source :
	mkdir -p stamp
	scripts/git-sync-repo.sh https://github.com/input-output-hk/cardano-sl.git source/cardano-sl
	touch $@

#-------------------------------------------------------------------------------
# Install node and npm (included with node) in order to build Daedalus.

tools/bin/node : stamp/check-tarball
	(cd source && tar xf $(PWD)/tarballs/node-v6.11.5.tar.gz)
	(cd source/node-v6.11.5 && ./configure --prefix=$(PWD)/tools && make install)
	touch $@

stamp/check-tarball : tarballs/node-v6.11.5.tar.gz
	sha256sum --check tarballs/sha256sum
	touch $@

tarballs/node-v6.11.5.tar.gz :
	curl -o $@ https://nodejs.org/dist/v6.11.5/node-v6.11.5.tar.gz

# ------------------------------------------------------------------------------
# Install Haskell tools jenga and mafia from source.

tools/bin/autoexporter : tools/bin/mafia
	mafia install autoexporter
	(cp $(MAFIA_HOME)/bin/autoexporter/bin/autoexporter $@)

tools/bin/markdown-unlit : tools/bin/mafia
	mafia install markdown-unlit
	(cp $(MAFIA_HOME)/bin/markdown-unlit/bin/markdown-unlit $@)

tools/bin/jenga : tools/bin/mafia
	mkdir -p tools/bin/
	scripts/git-sync-repo.sh  https://github.com/erikd/jenga source/jenga
	(cd source/jenga && mafia build)
	cp -f source/jenga/dist/build/jenga/jenga $@

tools/bin/mafia : stamp/cabal-update
	mkdir -p tools/bin/
	scripts/git-sync-repo.sh https://github.com/haskell-mafia/mafia source/mafia
	(cd source/mafia && git checkout topic/accept-lib)
	(cd source/mafia && script/mafia build)
	cp -f source/mafia/dist/build/mafia/mafia $@

# Update the local cabal data.
stamp/cabal-update :
	scripts/ghc-version-check.sh
	scripts/cabal-version-check.sh
	mkdir -p home results stamp tarballs tools/bin
	cabal update
	touch $@
