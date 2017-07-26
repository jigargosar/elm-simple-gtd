import * as _ from "ramda"
import fs from "fs"
import {run} from "runjs"
import assert from "assert"


function runFish(command, opt = {}) {
  return run(`fish -c '${command}' `, opt)
}


function parseModuleName(line) {
  const match = _.match(/^(?:port )?module ((?:\w|\.)+)/)(line)
  if (!match[1]) throw new Error(`Elm module name parse error in line: "${line}"`)
  return match[1]
}

// tests
assert.equal("aSomePortMod.a.x", parseModuleName("port module aSomePortMod.a.x e"))
assert.equal("AppColors.a.x", parseModuleName("module AppColors.a.x e"))

const getParentModuleNameOrNull =
    _.compose(
        _.join("."),
        _.init,
        _.split("."),
    )

function parseFile(fileName) {
  const lines = _.split("\n")(run("cat " + fileName, {stdio: 'pipe'}))
  const moduleName = parseModuleName(lines[0])
  // console.log("moduleName =", moduleName)
  const imports = _.pipe(
      _.map(_.match(/^import ((?:\w|\.)+)/)),
      _.reject(_.isEmpty),
      _.map(_.nth(1)),
  )(lines)
  // console.log("imports =", imports)
  // console.log(_.take(5, lines))
  
  const parentModule = getParentModuleNameOrNull(moduleName)
  
  console.log(_.split(".", moduleName))
  return {moduleName, imports, parentModule, fileName}
}

export async function dep() {
  const srcGlob = "src/elm/**.elm"
  
  const output = runFish(`find ${srcGlob}`, {stdio: 'pipe'})
  
  const fileNames = _.split("\n", output)
  
  
  const fileInfo = _.compose(
      _.map(parseFile),
      _.take(2),
      _.drop(20),
  )(fileNames)
  
  
  console.log("deps", fileInfo)
}



