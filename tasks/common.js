import {run} from "runjs"

export function runFish(command, opt = {}) {
  return run(`fish -c '${command}' `, opt)
}

export const Tasks = {
  sleep(ms) {
    return new Promise(resolve => {
      setTimeout(resolve, ms)
    })
  },
}
