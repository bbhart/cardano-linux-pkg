# cardano-linux-pkg

This is a Makefile that should be able to build [cardano] and the [daedalus]
wallet on any Linux system.

# It doesn't work yet!!!

However it is close.

### What is working.

* Building [mafia] and [jenga] Haskell build tools for source.
* Building `cardano-node` and `cardano-launcher` from the Haskell source.
* Installing a local build of `nodejs` and `npm` that is known to work.
* Using `npm` to grab required Node modules.
* Copying everything to a local install directory which can then be tarred up
  and (hopefully) moved to another machine where is can be installed and work
  correctly.

### What's not working.

Currently, when I run Daedalus, I get the following error in the electon Console:
```
Uncaught Error: Cannot find module "daedalus-client-api"
```

### To do.

* Make it work (see above).
* Add a proper installer ([appimage] maybe?).
* Move per-wallet SSL certificate generation to `${CFGDIR}`.



[appimage]: https://appimage.org/
[cardano]: https://github.com/input-output-hk/cardano-sl
[daedalus]: https://github.com/input-output-hk/daedalus
[jenga]: https://github.com/erikd/jenga
[mafia]: https://github.com/haskell-mafia/mafia
