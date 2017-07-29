import * as _ from "ramda"
import fs from "fs"
import {runFish} from "../common"
import {Module, Modules} from "./module"

const computeDependencies = function () {
  const srcGlob = "src/elm/**.elm"
  
  const output = runFish(`find ${srcGlob}`, {stdio: 'pipe'})
  
  const isBlank = _.compose(_.isEmpty, _.trim)
  const fileNames = _.compose(_.reject(isBlank), _.split("\n"))(output)
  
  
  const moduleList = _.compose(
      _.map(Module),
      // _.take(2),
      // _.drop(20),
  )(fileNames)
  
  return Modules(moduleList)
}

export function logTransitiveImportsOf(moduleName) {
  const module = computeDependencies()[moduleName]
  const transitiveBackwardImports =
      module ? _.pick([
            "transitiveBackwardImports",
            "transitiveBackwardImportsCount",
            "transitiveImports",
            "transitiveImportsCount",
          ],
      )(module) : []
  console.log(JSON.stringify({transitiveBackwardImports}, null, 2))
  return transitiveBackwardImports
}

export function generateDependenciesStatsFile() {
  const modules = computeDependencies()
  
  fs.writeFileSync(
      "stats/elm-src-dependencies.json",
      JSON.stringify(modules, null, 2),
      "UTF-8",
  )
  // console.log("dep", modules["Document"])
}



