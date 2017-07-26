import {run} from "runjs"
export function runFish(command, opt = {}) {
  return run(`fish -c '${command}' `, opt)
}

