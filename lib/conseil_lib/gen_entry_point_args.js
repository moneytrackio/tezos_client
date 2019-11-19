"use strict";
exports.__esModule = true;
var conseiljs_1 = require("conseiljs");
function selectEntryPoint(parmsStruct, entryPointsName) {
    var entryPoints = conseiljs_1.TezosContractIntrospector.generateEntryPointsFromParams(parmsStruct);
    if (entryPoints.length == 1) {
        return entryPoints[0];
    }
    console.log(entryPoints);
    for (var iter in entryPoints) {
        var entryPoint = entryPoints[iter];
        if (entryPoint["name"].toLowerCase() == entryPointsName.toLowerCase()) {
            return entryPoint;
        }
    }
}
if (process.argv.length < 4) {
    console.log("USAGE: node convert_to_moicheline.js PARAM_STRUCT ENTRY_POINT [PARAMS ...]\nARGS ::\n\tPARAM_STRUCT: paraleter contract stuctur description\n\t");
}
else {
    var paramsStruct = process.argv[2];
    var entryPointsName = process.argv[3];
    var params = [];
    if (process.argv.length > 4) {
        params = process.argv.slice(4);
    }
    var entryPoint = selectEntryPoint(paramsStruct, entryPointsName);
    console.log(conseiljs_1.TezosLanguageUtil.translateMichelsonToMicheline(entryPoint.generateParameter.apply(entryPoint, params)));
}
