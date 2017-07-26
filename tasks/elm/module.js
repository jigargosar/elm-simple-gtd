import * as _ from "ramda"
import {run} from "runjs"
import assert from "assert"
import fs from "fs"

function parseModuleName(line) {
  const match = _.match(/^(?:port )?module ((?:\w|\.)+)/)(line)
  if (!match[1]) throw new Error(`Elm module name parse error in line: "${line}"`)
  return match[1]
}

// tests
assert.equal("aSomePortMod.a.x", parseModuleName("port module aSomePortMod.a.x e"))
assert.equal("AppColors.a.x", parseModuleName("module AppColors.a.x e"))

const getParentModuleName =
    _.compose(
        _.join("."),
        _.init,
        _.split("."),
    )

export function Module(fileName) {
  // const lines = _.split("\n")(run("cat " + fileName, {stdio: 'pipe'}))
  const lines = _.split("\n")(fs.readFileSync(fileName, {encoding: "UTF-8"}))
  
  const moduleName = parseModuleName(lines[0])
  // console.log("moduleName =", moduleName)
  const imports = _.compose(
      _.map(_.nth(1)),
      _.reject(_.isEmpty),
      _.map(_.match(/^import ((?:\w|\.)+)/)),
  )(lines)
  // console.log("imports =", imports)
  // console.log(_.take(5, lines))
  
  const parentModuleName = getParentModuleName(moduleName)
  
  return {fileName, moduleName, parentModuleName ,imports, importsCount:_.length(imports)}
}


const addTransitiveDependencies = moduleMap => {
  // console.log(moduleMap)
  
  function getImportsOfModule(moduleName) {
    const module = moduleMap[moduleName]
    return module ? module.imports : []
  }
  
  const getTransitiveImports = _.memoize(function (moduleName) {
    // console.log(moduleName)
    const moduleImports = getImportsOfModule(moduleName)
    return _.compose(
        _.uniq,
        _.sortBy(_.identity),
        _.concat(moduleImports),
        _.flatten
        , _.map(getTransitiveImports),
    )(moduleImports)
  })
  
  return _.map((module) => {
    // const dependencies = _.pick(module.imports)(moduleMap)
    const transitiveImports = getTransitiveImports(module.moduleName)
    return _.merge(module, {
      transitiveImports,
      transitiveImportsCount:_.length(transitiveImports),
      // dependencies,
      // dependenciesCount: _.compose(_.length, _.values)(dependencies)
    })
  })(moduleMap)
  
}

function addBackwardDependencies(moduleMap) {
  
  function getBackwardDependencies(moduleName) {
    return _.filter(_.compose(
        _.contains(moduleName),
        _.prop("imports"),
    ))(moduleMap)
  }
  
  const getBackwardImports = _.compose(_.keys,getBackwardDependencies)
  
  
  const getTransitiveBackwardImports = _.memoize(function (moduleName) {
    const dependentModuleNames = _.compose(
        _.keys,
        getBackwardDependencies,
    )(moduleName)
    
    
    return _.compose(
        _.uniq,
        _.sortBy(_.identity),
        _.flatten,
        _.concat(dependentModuleNames),
        _.map(getTransitiveBackwardImports)
    )(dependentModuleNames)
  }
)
  
  return _.map(module => {
    // const backwardDependencies = getBackwardDependencies(module.moduleName)
    const transitiveBackwardImports = getTransitiveBackwardImports(module.moduleName)
    const backwardImports = getBackwardImports(module.moduleName)
    return _.merge(module, {
      // backwardDependencies,
      // backwardDependenciesCount:_.compose(_.length, _.values)(backwardDependencies),
      backwardImports,
      backwardImportsCount:_.length(backwardImports),
      transitiveBackwardImports,
      transitiveBackwardImportsCount:_.length(transitiveBackwardImports)
    })
  })(moduleMap)
}

export function Modules(moduleList) {
  const moduleMap = _.zipObj(_.map(_.prop("moduleName"))(moduleList), moduleList)
  return addBackwardDependencies(addTransitiveDependencies(moduleMap))
}
