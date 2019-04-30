# This script is used in .travis.yml for continuous integration on travis.
# Travis CI is done on Ubuntu trusty

export OPAMYES=1
wget https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh
yes "" | sh install.sh

opam switch create liquidity 4.06.1  || opam switch set liquidity

eval $(opam config env)

opam update