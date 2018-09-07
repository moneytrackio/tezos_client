#!/bin/sh
set -ex
wget https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh
yes "" | sh install.sh