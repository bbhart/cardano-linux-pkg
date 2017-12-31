
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


#-------------------------------------------------------------------------------
# Daedelus related stuff.

results/run-daedalus.sh : scripts/run-daedalus.sh
	cp -f $+ $@
	chmod u+x $@

results/Daedalus-linux-x64/LICENSE : source/daedalus/release/linux-x64/Daedalus-linux-x64/LICENSE
	cp -r source/daedalus/release/linux-x64/Daedalus-linux-x64 $(shell dirname $@)

source/daedalus/release/linux-x64/Daedalus-linux-x64/LICENSE : source/daedalus/node_modules/tar/LICENSE
	(cd source/daedalus && npm run package --icon source/daedalus/installers/icons/256x256.png)

source/daedalus/node_modules/tar/LICENSE : source/daedalus/node_modules/daedalus-client-api/README.md
	(cd source/daedalus/node_modules/daedalus-client-api && npm install)
	(cd source/daedalus && npm link && npm install)

source/daedalus/node_modules/daedalus-client-api/README.md : source/daedalus/LICENSE
	rm -rf source/daedalus/node_modules/daedalus-client-api
	cp -r source/cardano-sl/daedalus source/daedalus/node_modules/daedalus-client-api
	touch $@

source/daedalus/LICENSE : tools/bin/node
	@if test -d source/daedalus ; then \
		(cd source/daedalus && git pull --rebase) ; \
	else \
	    git clone https://github.com/input-output-hk/daedalus source/daedalus ; \
	    fi
	touch $@

#-------------------------------------------------------------------------------
# Auxillary files.

results/log-config-prod.yaml : source/cardano-sl/stack.yaml
	cp -f $+ $@

results/mainnet-genesis-dryrun-with-stakeholders.json : source/cardano-sl/stack.yaml
	cp -f $+ $@

results/mainnet-genesis.json : source/cardano-sl/stack.yaml
	cp -f $+ $@

results/mainnet-staging-short-epoch-genesis.json : source/cardano-sl/stack.yaml
	cp -f $+ $@

results/configuration.yaml : source/cardano-sl/stack.yaml
	cp -f $+ $@

results/build-certificates-unix.sh : source/daedalus/installers/build-certificates-unix.sh
	cp -f $+ $@

results/wallet-topology.yaml : source/daedalus/installers/wallet-topology.yaml
	cp -f $+ $@

results/ca.conf : source/daedalus/installers/ca.conf
	rm -f results/{ca,client,server}.conf
	cp -f source/daedalus/installers/{ca,client,server}.conf results/

#-------------------------------------------------------------------------------
# Build cardano-launcher and cardano-node

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
		(cd source/cardano-sl/ && git pull --rebase && jenga init -m submods -d directory) ; \
		fi
	(cd source/cardano-sl/ && git reset origin/develop)
	(cd source/cardano-sl/ && git add .gitmodules && git commit -m "Add submodules" -- . )
	touch $@

source/cardano-sl/stack.yaml :
	@if test -d source/cardano-sl ; then \
		(cd source/cardano-sl && git pull --rebase) ; \
	else \
	    git clone https://github.com/input-output-hk/cardano-sl.git source/cardano-sl ; \
	    fi
	(cd source/cardano-sl/ && git checkout develop)
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

tools/bin/mafia :
	mkdir -p bin
	@if test -d source/mafia ; then \
		(cd source/mafia && git pull --rebase) ; \
	else \
	    git clone https://github.com/haskell-mafia/mafia source/mafia ; \
	    fi
	(cd source/mafia && script/mafia build)
	cp -f source/mafia/dist/build/mafia/mafia $@
