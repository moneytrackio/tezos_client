"use strict";
exports.__esModule = true;
var ConseilJs = require("conseiljs");

if (process.argv.length != 3) {
    console.log("USAGE: node convert_to_micheline.js CODE\nARGS:: \n\tCODE: michelson script");
    process.exit(-1);
} else {
    console.log(ConseilJs.TezosLanguageUtil.translateMichelsonToMicheline(process.argv[2]));
    process.exit(0);
}
