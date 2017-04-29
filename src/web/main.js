"use strict";

const _ = require("ramda")

require("./pcss/main.pcss")

const DB = require("./local-pouch-db")
const sound = require("./sound")

async function boot() {
    let syncList = []
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
        pouchDBRemoteSyncURI: localStorage.getItem("pouchdb.remote-sync-uri") || ""
    }

    const Elm = require("elm/Main.elm")
    const app = Elm["Main"]
        .embed(document.getElementById("root"), flags)


    app.ports["syncWithRemotePouch"].subscribe(async (uri) => {
        localStorage.setItem("pouchdb.remote-sync-uri", uri)
        await Promise.all(_.map(sync => sync.cancel())(syncList))
        syncList = _.compose(_.map(db => db.startRemoteSync(uri, "sgtd2-")), _.values)(dbMap)
    })


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
                    // console.log(toFocus.inputElement, toFocus.$.input)
                    toFocus.inputElement.focus()
                    // toFocus.$.input.focus()
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

    if (!'serviceWorker' in navigator) {
        console.warn("servieWorker not found in navigator")
        return
    }

    const swScriptPath = WEB_PACK_DEV_SERVER ? "/notification-sw.js" : '/service-worker.js'

    navigator.serviceWorker.addEventListener('message', event => {
        console.info("message event received", event.data)
        app.ports["notificationClicked"].send(event.data)
        // event.ports[0].postMessage("Client 1 Says 'Hello back!'");
    });
    const reg = await navigator.serviceWorker.register(swScriptPath)

    app.ports["showNotification"].subscribe(showNotification(reg))
    app.ports["closeNotification"].subscribe(closeNotification(reg))

}

const closeNotification = reg => async (tag) => {
    const n = _.find(_.propEq("tag", tag), await reg.getNotifications())
    if (n) {
        n.close()
    }
}

const showNotification = reg => async ({tag, title, data}) => {
    //console.info(msg)
    const permission = await Notification.requestPermission()
    if (permission !== "granted") return
    reg.showNotification(title, {
        tag,
        requiresInteraction: true,
        sticky: true,
        renotify: true,
        vibrate: [500, 110, 500, 110, 450, 110, 200, 110, 170, 40, 450, 110, 200, 110, 170, 40, 500],
        sound: "/alarm.ogg",
        actions: [
            {title: "Mark Done", action: "mark-done"},
            {title: "Snooze", action: "snooze"},
        ],
        body: title,
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
