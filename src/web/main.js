"use strict";

import "./pcss/main.pcss"

import "./index.html"


const Elm = require("elm/Main.elm")
const app = Elm["Main"].embed(document.getElementById("root"), {now: Date.now()})

