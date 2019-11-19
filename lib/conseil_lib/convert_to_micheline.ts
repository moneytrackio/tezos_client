import { TezosLanguageUtil } from "conseiljs";

if (process.argv.length != 3) {
  console.log("USAGE: node convert_to_moicheline.js CODE\nARGS:: \n\tCODE: michelson script");
} else {
  console.log(TezosLanguageUtil.translateMichelsonToMicheline(process.argv[2]));
}
