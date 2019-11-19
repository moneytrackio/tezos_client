import {
  TezosContractIntrospector,
  TezosLanguageUtil
} from "conseiljs";

function selectEntryPoint(parmsStruct, entryPointsName) {
  let entryPoints = TezosContractIntrospector.generateEntryPointsFromParams(parmsStruct);

  if (entryPoints.length == 1) {
    return entryPoints[0];
  }

  for (let iter in entryPoints) {
    let entryPoint = entryPoints[iter];
    if (entryPoint["name"].toLowerCase() == entryPointsName.toLowerCase()) {
      return entryPoint;
    }
  }
}

if (process.argv.length < 4) {
   console.log("USAGE: node convert_to_moicheline.js PARAM_STRUCT ENTRY_POINT [PARAMS ...]\nARGS ::\n\tPARAM_STRUCT: paraleter contract stuctur description\n\t");
} else {
  let paramsStruct = process.argv[2];
  let entryPointsName = process.argv[3];
  let params = [];
  if (process.argv.length > 4) {
    params = process.argv.slice(4);
  }

  let entryPoint = selectEntryPoint(paramsStruct, entryPointsName);
  console.log(TezosLanguageUtil.translateMichelsonToMicheline(entryPoint.generateParameter(...params)));
}
