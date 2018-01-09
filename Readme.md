# cardano-linux-pkg

This is a Makefile that should be able to build [cardano] and the [daedalus]
wallet on any Linux system.

This code should as is as long as you have the required dependencies installed.

### What the build script does.

* Builds the [mafia] and [jenga] Haskell build tools from source.
* Builds `cardano-node` and `cardano-launcher` from the Haskell source.
* Installs a local build of `nodejs` and `npm` that is known to work.
* Uses `npm` to grab required Node modules.
* Copies everything to a local install directory (`results/`) which can then be
  tarred up and (hopefully) moved to another machine where is can be installed
  and work correctly.


### To do.

* Add a proper installer ([appimage] maybe?).
* Move per-wallet SSL certificate generation to `${CFGDIR}`.

### Building it.

Firstly you should perform due diligence on this code. If you run this in a VM
you don't really need to trust the code or the author. If you are going to run
it on any machine which crypto currencies or crypto keys (SSH, GPG etc), you
should probably inspect the the `Makefile` and the sources to mafia and jenga
to make sure this code doesn't steal all your secrets.

On most Linux system you will need to usual development tools plus the pre-requisites
listed at the top of the `Makefile`. Once that is installed, and this repo
cloned, building it (which takes a considerable amount of time) is just a matter
of:
```
make
(cd results/ && build-certificates-unix.sh)
results/run-daedalus.sh
```

There are likely to be some errors printed to stdout, and I have
[raised an issue](https://github.com/input-output-hk/daedalus/issues/635) about
that.





[appimage]: https://appimage.org/
[cardano]: https://github.com/input-output-hk/cardano-sl
[daedalus]: https://github.com/input-output-hk/daedalus
[jenga]: https://github.com/erikd/jenga
[mafia]: https://github.com/haskell-mafia/mafia
