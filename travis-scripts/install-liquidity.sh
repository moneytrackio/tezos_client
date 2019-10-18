#!/bin/sh
#set -ex
# This script is used in .travis.yml for continuous integration on travis.
# BTW, it also show some needed system packages to build liquidity
# Travis CI is done on Ubuntu trusty
export OPAMYES=1

[ -d "liquidity/.git" ] || git clone --depth=50 https://github.com/OCamlPro/liquidity.git liquidity
cd liquidity
git pull
# git checkout next
git checkout 5ed5b09674cb96f8cd4ac83a55621f77d9a9110c

eval `opam config env`

opam install camlp4 ctypes-foreign ocaml-migrate-parsetree
make build-deps
make clone-tezos
make
make install