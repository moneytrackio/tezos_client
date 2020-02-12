## Copyright 2019 Smart Chain Arena LLC. ##

# To run this script, we need to setup a PYTHONPATH to the
# SmartPyBasic directory.

# If the SmartPyBasic directory is ~/SmartPyBasic, then
#   PYTHONPATH=~/SmartPyBasic python3 demo.py
# or
#   ~/SmartPyBasic/SmartPy.sh run demo.py
# should work.

import smartpy as sp

class MyContract(sp.Contract):
    def __init__(self):
        self.init(
            big_map_first = sp.big_map(
                tkey = sp.TString,
                tvalue = sp.TInt
            ),
            big_map_second = sp.big_map(
                 tkey = sp.TString,
                 tvalue = sp.TString
             )
        )

    @sp.entry_point
    def add_first(self, params):
        self.data.big_map_first[params.key] = params.value

    @sp.entry_point
    def add_second(self, params):
        self.data.big_map_second[params.key] = params.value