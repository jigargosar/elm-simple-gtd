"use strict";

import "./pcss/main.pcss"

import "./index.html"

import PouchDB from "./local-pouch-db"


const todoDB = PouchDB("todo-db")

console.log(todoDB)

const Elm = require("elm/Main.elm")
const app = Elm["Main"].embed(document.getElementById("root"), {now: Date.now()})

