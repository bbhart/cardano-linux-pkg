
# Pre-reqisites:
#     cabal-install-1.24
#     g++
#     gcc
#     ghc-8.0
#     liblzma-dev
#     librocksdb-dev
#     libsnappy-dev
#     libssl-dev
#     make

DATE = $(shell date)
PWD := $(shell pwd)

export HOME = $(PWD)/home

# Want the local path to come before global paths.
export PATH := $(PWD)/tools/bin:/usr/bin:/bin

export MAFIA_PATH := $(PWD)/mafia

TOOLS = tools/bin/jenga tools/bin/mafia

CARDANO_BRANCH = develop

MAFIA_DROP_DEP = directory,binary-example,chat,latency

all : results/cardano-launcher results/cardano-node results/run-daedalus.sh \
		results/Daedalus-linux-x64/Daedalus $(AUX_TARGETS)

#-------------------------------------------------------------------------------
# Daedelus related stuff.

results/run-daedalus.sh : scripts/run-daedalus.sh
	cp -f $+ $@
	chmod u+x $@

results/Daedalus-linux-x64/Daedalus : source/daedalus/release/linux-x64/Daedalus-linux-x64/Daedalus
	cp -r source/daedalus/release/linux-x64/Daedalus-linux-x64 $(shell dirname $@)

source/daedalus/release/linux-x64/Daedalus-linux-x64/Daedalus : source/daedalus/node_modules/daedalus-client-api/package.json
	(cd source/daedalus && npm run package --icon source/daedalus/installers/icons/256x256.png)

source/daedalus/node_modules/daedalus-client-api/package.json : stamp/daedalus-source stamp/daedalus-bridge
	rm -rf source/daedalus/node_modules/daedalus-client-api
	(cd source/daedalus && npm install)
	cp -r source/cardano-sl/daedalus source/daedalus/node_modules/daedalus-client-api
	touch $@

stamp/daedalus-source : tools/bin/node
	@if test -d source/daedalus ; then \
		(cd source/daedalus && git pull --rebase) ; \
	else \
	    git clone https://github.com/input-output-hk/daedalus source/daedalus ; \
	    fi
	touch $@

#-------------------------------------------------------------------------------
# Auxillary files.

clean-aux :
	rm -f $(AUX_TARGETS)

install-aux :
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

stamp/daedalus-bridge : tools/bin/cardano-wallet-hs2purs
	(cd source/cardano-sl && cardano-wallet-hs2purs)
	(cd source/cardano-sl/daedalus && npm install)
	touch $@

tools/bin/cardano-wallet-hs2purs : source/cardano-sl/.jenga $(TOOLS)
	(cd source/cardano-sl/wallet && mafia build cardano-wallet-hs2purs)
	(cp -f source/cardano-sl/wallet/dist/build/cardano-wallet-hs2purs/cardano-wallet-hs2purs $@)

results/cardano-launcher : source/cardano-sl/.jenga $(TOOLS)
	mkdir -p results
	(cd source/cardano-sl/tools && mafia build cardano-launcher)
	cp -f source/cardano-sl/tools/dist/build/cardano-launcher/cardano-launcher $@

results/cardano-node : source/cardano-sl/.jenga $(TOOLS)
	mkdir -p results
	(cd source/cardano-sl/wallet && mafia build cardano-node)
	cp -f source/cardano-sl/wallet/dist/build/cardano-node/cardano-node $@

source/cardano-sl/.jenga : source/cardano-sl/stack.yaml $(TOOLS)
	@if test -f $@ ; then \
		(cd source/cardano-sl/ && git pull --rebase && jenga update) ; \
	else \
		(cd source/cardano-sl/ && git pull --rebase && jenga init -m submods -d ${MAFIA_DROP_DEP}) ; \
		fi
	(cd source/cardano-sl/ && git reset origin/$(CARDANO_BRANCH))
	(cd source/cardano-sl/ && git add .gitmodules submods && git commit -m "Add submodules" -- . )
	touch $@

source/cardano-sl/stack.yaml :
	@if test -d source/cardano-sl ; then \
		(cd source/cardano-sl && git pull --rebase) ; \
	else \
	    git clone https://github.com/input-output-hk/cardano-sl.git source/cardano-sl ; \
	    fi
	(cd source/cardano-sl/ && git checkout $(CARDANO_BRANCH))
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
	mkdir -p tarballs
	curl -o $@ https://nodejs.org/dist/v6.11.5/node-v6.11.5.tar.gz

# ------------------------------------------------------------------------------
# Install Haskell tools mafia and jenga from source.

tools/bin/jenga : tools/bin/mafia
	@if test -d source/jenga ; then \
		(cd source/jenga && git pull --rebase) ; \
	else \
	    git clone https://github.com/erikd/jenga source/jenga ; \
	    fi
	(cd source/jenga && mafia build)
	cp -f source/jenga/dist/build/jenga/jenga $@

tools/bin/mafia : stamp/cabal-update
	mkdir -p bin
	@if test -d source/mafia ; then \
		(cd source/mafia && git pull --rebase) ; \
	else \
	    git clone https://github.com/haskell-mafia/mafia source/mafia ; \
	    fi
	(cd source/mafia && git checkout topic/accept-lib)
	(cd source/mafia && script/mafia build)
	cp -f source/mafia/dist/build/mafia/mafia $@

# Update the local cabal data.
stamp/cabal-update :
	mkdir -p stamp
	cabal update
	touch $@
