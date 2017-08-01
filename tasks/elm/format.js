import {runFish, Tasks} from "../common"

export const Format = {
  formatBuffer() {
    runFish("pbpaste | elm-format --stdin | pbcopy")
  }
}

