"use strict";

import "./pcss/main.pcss"

import "./index.html"

import PouchDB from "./local-pouch-db"


async function boot() {
    const todoDB = await PouchDB("todo-db")

    const allTodos = await todoDB.allDocs()

    console.log(allTodos)
    const Elm = require("elm/Main.elm")
    const app = Elm["Main"].embed(document.getElementById("root"), {now: Date.now()})

}

boot().catch(console.error)




