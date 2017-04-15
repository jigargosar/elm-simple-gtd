"use strict";


import PouchDB from "./local-pouch-db"

import R from "ramda"

import sound from "./sound"

import Sync from "./sync"

const _ = R

async function boot() {

    const dbMap = {
        "todo-db": await PouchDB("todo-db"),
        "project-db": await PouchDB("project-db"),
        "context-db": await PouchDB("context-db")
    }

    const allTodos = await dbMap["todo-db"].find({selector: {"_id": {"$ne": null}}})
    const allProjects = await dbMap["project-db"].find({selector: {"_id": {"$ne": null}}})
    const contexts = await dbMap["context-db"].find({selector: {"_id": {"$ne": null}}})
    // console.log(allTodos)

    const Elm = require("elm/Main.elm")
    const app = Elm["Main"]
        .embed(document.getElementById("root"), {
            now: Date.now(),
            encodedTodoList: allTodos,
            encodedProjectList: allProjects,
            encodedContextList: contexts,
            myPeerId : localStorage.getItem("my-peer-id") || "",
            remotePeerId : localStorage.getItem("remote-peer-id") || ""
        })

    // const sync = Sync(app, dbMap)

    app.ports["pouchDBUpsert"].subscribe(async ([dbName, id, doc]) => {
        // console.log("upserting", dbName, doc, id)
        const upsertResult = await dbMap[dbName].upsert(id, doc)
        if (_.F()) {
            console.log("upsertResult", upsertResult)
        }
    });



    app.ports["focusPaperInput"].subscribe((selector) => {
        setTimeout(() => {
            requestAnimationFrame(() => {
                const toFocus = document.querySelector(selector)
                // console.log("toFocus", toFocus, document.activeElement)
                if (toFocus && document.activeElement !== toFocus) {
                    toFocus.focus()
                } else {
                    // console.log("not focusing")
                }
                if (toFocus) {
                    toFocus.$.input.focus()
                }
            })
        }, 0)
    })


    app.ports["startAlarm"].subscribe(() => {
        sound.start()
    })


    app.ports["stopAlarm"].subscribe(() => {
        sound.stop()
    })
}

boot().catch(console.error)

//noinspection JSUnresolvedVariable
if (!WEB_PACK_DEV_SERVER &&'serviceWorker' in navigator) {
    //noinspection JSUnresolvedVariable
    navigator.serviceWorker.register('/service-worker.js');
}
