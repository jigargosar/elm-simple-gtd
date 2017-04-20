"use strict";

const _ = require("ramda")

require("./pcss/main.pcss")

const DB = require("./local-pouch-db")
const sound = require("./sound")

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
        encodedContextList: contexts
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

    if (!'serviceWorker' in navigator) return
    const swScriptPath = WEB_PACK_DEV_SERVER ? "/notification-sw.js" : '/service-worker.js'

    navigator.serviceWorker.addEventListener('message', event => {
        console.info("message event received", event.data)
        app.ports["notificationClicked"].send(event.data)
        // event.ports[0].postMessage("Client 1 Says 'Hello back!'");
    });
    const reg = await navigator.serviceWorker.register(swScriptPath)

    app.ports["showNotification"].subscribe(showNotification(reg))

}

const showNotification = reg => async ({tag, title, data}) => {
    //console.info(msg)
    const permission = await Notification.requestPermission()
    if (permission !== "granted") return
    reg.showNotification(title, {
        tag,
        requiresInteraction:true,
        sticky:true,
        renotify:true,
        vibrate: [500,110,500,110,450,110,200,110,170,40,450,110,200,110,170,40,500],
        sound:"/alarm.ogg",
        actions: [
            {title: "Mark Done", action: "mark-done"},
            {title: "Snooze", action: "snooze"},
        ],
        data
    })
}
/*
 //noinspection JSUnresolvedVariable
 if (!WEB_PACK_DEV_SERVER && 'serviceWorker' in navigator) {
 //noinspection JSUnresolvedVariable
 navigator.serviceWorker.register('/service-worker.js');
 }
 */
