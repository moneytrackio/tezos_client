"use strict";
exports.__esModule = true;
var conseiljs_1 = require("conseiljs");
if (process.argv.length != 3) {
    console.log("USAGE: node convert_to_moicheline.js CODE\nARGS:: \n\tCODE: michelson script");
}
else {
    console.log(conseiljs_1.TezosLanguageUtil.translateMichelsonToMicheline(process.argv[2]));
}
