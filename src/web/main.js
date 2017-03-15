"use strict";

import "./pcss/main.pcss"

import "./index.html"

import PouchDB from "./local-pouch-db"


async function boot() {

    const dbMap = {
        "todo-db":await PouchDB("todo-db")
    }

    const allTodos = await dbMap["todo-db"].allDocs()

    console.log(allTodos)
    const Elm = require("elm/Main.elm")
    const app = Elm["Main"].embed(document.getElementById("root"), {now: Date.now()})


    app.ports["pouchDBBulkDocks"].subscribe(async([dbName, docs]) => {
        const bulkResult = await dbMap[dbName].bulkDocs(docs)
        // console.log("bulkResult:", dbName, bulkResult, docs)
        app.ports["onPouchDBBulkDocksResponse"].send([dbName, bulkResult, docs])
    })

}

boot().catch(console.error)




