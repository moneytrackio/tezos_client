#!/bin/sh
set -ex
# This script is used in .travis.yml for continuous integration on travis.
# BTW, it also show some needed system packages to build liquidity
# Travis CI is done on Ubuntu trusty

[ -d liquidity ] || git clone --depth=50 https://github.com/OCamlPro/liquidity.git liquidity
cd liquidity
git pull
git checkout next

# currently, we only target OCaml 4.06.1 because we reuse the parser of OCaml
opam switch create liquidity 4.06.1

eval $(opam config env)
opam update
eval $(opam config env)

echo $PWD

make build-deps
make clone-tezos
tezos/scripts/install_build_deps.raw.sh
# make -C tezos build-deps

make
make install