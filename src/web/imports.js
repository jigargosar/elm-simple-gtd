// noinspection NpmUsedModulesInstalled
import {Imports} from "elm/Imports.elm"

const app = Imports.worker()

app.ports["output"].subscribe(console.log)

