"use strict";


const DB = require("./local-pouch-db")

const _ = require("ramda")

import sound from "./sound"

async function boot() {

    const dbMap = {
        "todo-db": await DB("todo-db"),
        "project-db": await DB("project-db"),
        "context-db": await DB("context-db")
    }

    // _.mapObjIndexed(db=>db.startRemoteSync(), dbMap)

    const todos = await dbMap["todo-db"].find({selector: {"_id": {"$ne": null}}})
    const projects = await dbMap["project-db"].find({selector: {"_id": {"$ne": null}}})
    const contexts = await dbMap["context-db"].find({selector: {"_id": {"$ne": null}}})

    const flags = {
        now: Date.now(),
            encodedTodoList: todos,
        encodedProjectList: projects,
        encodedContextList: contexts,
        myPeerId: localStorage.getItem("my-peer-id") || "",
        remotePeerId: localStorage.getItem("remote-peer-id") || ""
    }

    const Elm = require("elm/Main.elm")
    const app = Elm["Main"]
        .embed(document.getElementById("root"), flags)

    app.ports["pouchDBUpsert"].subscribe(async ([dbName, id, doc]) => {
        // console.log("upserting", dbName, doc, id)
        const upsertResult = await dbMap[dbName].upsert(id, doc)
        if (_.F()) {
            console.log("upsertResult", upsertResult)
        }
    });


    setupNotifications(app)
        .catch(console.error)

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


async function setupNotifications(app) {
    if ('serviceWorker' in navigator) {
        const reg = await navigator.serviceWorker.register('/notification-sw.js')
        app.ports["showTestNotification"].subscribe(async (msg) => {
            const permission = await Notification.requestPermission()
            if (permission === "granted") {
                reg.showNotification("hi there",
                    {
                        actions: [{title: "foo", name: "bar", action: "adf"}],
                        body: "asdf",
                        title: "Hi There!!"
                    })
                // var notification = new Notification("hi there",{actions:[{title:"foo", name:"bar", action:"adf"}],body:"asdf", title:"Hi There!!"});
                // notification.addEventListener("click", e=>console.info("notification clicked"))
            }
            return console.info(msg)
        })
    }
}

//noinspection JSUnresolvedVariable
if (!WEB_PACK_DEV_SERVER && 'serviceWorker' in navigator) {
    //noinspection JSUnresolvedVariable
    navigator.serviceWorker.register('/service-worker.js');
}
