## Copyright 2019 Smart Chain Arena LLC. ##

# To run this script, we need to setup a PYTHONPATH to the
# SmartPyBasic directory.

# If the SmartPyBasic directory is ~/SmartPyBasic, then
#   PYTHONPATH=~/SmartPyBasic python3 demo.py
# or
#   ~/SmartPyBasic/SmartPy.sh run demo.py
# should work.

import smartpy as sp
import sys
import json

class MyContract(sp.Contract):
    def __init__(self, big_map_first, big_map_second):
        self.init(
            big_map_first = sp.big_map(
                tkey = sp.TString,
                tvalue = sp.TInt,
                l = big_map_first
            ),
            big_map_second = sp.big_map(
                 tkey = sp.TString,
                 tvalue = sp.TString,
                 l = big_map_second
             )
        )

    @sp.entry_point
    def add_first(self, params):
        self.data.big_map_first[params.key] = params.value

    @sp.entry_point
    def add_second(self, params):
        self.data.big_map_second[params.key] = params.value

    @sp.entry_point
    def add_third(self, params):
        self.data.big_map_second[params.key] = params.first + params.second + params.third

    @sp.entry_point
    def always_fail(self, params):
        sp.set_type(params.amount, sp.TNat)
        sp.if params.amount >= 0:
          sp.failwith("I'm failing")



inputs = list(map(lambda input: json.loads(input), sys.argv[1:]))

sp.add_compilation_target("default", MyContract(*inputs))

