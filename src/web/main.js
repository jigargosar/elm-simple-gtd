"use strict";

import "./pcss/main.pcss"

import "./index.html"

import PouchDB from "./local-pouch-db"

import R from "ramda"

import sound from "./sound"

const _ = R

async function boot() {

    const dbMap = {
        "todo-db": await PouchDB("todo-db")
    }

    const allTodos = await dbMap["todo-db"].find({selector: {"_id": {"$ne": null}}})
    // console.log(allTodos)

    const Elm = require("elm/Main.elm")
    const app = Elm["Main"]
        .embed(document.getElementById("root"), {now: Date.now(), encodedTodoList: allTodos})


    app.ports["pouchDBBulkDocks"].subscribe(async([dbName, docs]) => {
        const bulkResult = await dbMap[dbName].bulkDocs(docs)
        // const conflicts =
        //     _.filter(_.compose(_.propEq("name", "conflict"), _.head)
        //     )(_.zip(bulkResult, docs))
        // console.log(conflicts)
        //
        console.log("bulkResult:", dbName, bulkResult, docs)
        app.ports["onPouchDBBulkDocksResponse"].send([dbName, bulkResult, docs])
    })

    app.ports["pouchDBUpsert"].subscribe(async([dbName, id, doc]) => {
        const upsertResult = await dbMap[dbName].upsert(id, doc)
        if (_.F()) {
            console.log("upsertResult", upsertResult)
        }
    });


    app.ports["documentQuerySelectorAndFocus"].subscribe((selector) => {
        setTimeout(() => {
            requestAnimationFrame(() => {
                const selected = document.querySelector(selector)
                if (selected) {
                    selected.focus()
                }
            })
        }, 0)
    })

}

boot().catch(console.error)




