import * as _ from "ramda"
import fs from "fs"
import {runFish} from "../common"
import {Module, Modules} from "./module"

export async function dep() {
  const srcGlob = "src/elm/**.elm"
  
  const output = runFish(`find ${srcGlob}`, {stdio: 'pipe'})
  
  const isBlank = _.compose(_.isEmpty, _.trim)
  const fileNames = _.compose(_.reject(isBlank),_.split("\n"))(output)
  
  
  const moduleList = _.compose(
      _.map(Module),
      // _.take(2),
      // _.drop(20),
  )(fileNames)
  
  const modules = Modules(moduleList)
  
  console.log("deps", modules["Document"])
}


