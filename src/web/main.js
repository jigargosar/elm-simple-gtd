"use strict";

const _ = require("ramda")

require("./pcss/main.pcss")


const sound = require("./sound")
const $ = require("jquery")
window.jQuery = $
require("./jquery.trap")
require("jquery-ui/ui/position")
const Notifications = require("./notifications")
import DB from "./pouchdb-wrapper"

//noinspection JSUnresolvedVariable
const developmentMode = NODE_ENV !== "production"
const firebaseConfig =
    developmentMode ? require("./config/prod/firebase")
        : require("./config/dev/firebase")

boot().catch(console.error)
async function boot() {
    $("#root").trap();

    const dbMap = {
        "todo-db": await DB("todo-db"),
        "project-db": await DB("project-db"),
        "context-db": await DB("context-db")
    }
    const allDocsMap = _.map(db => db.findAll())(dbMap)

    const flags = {
        now: Date.now(),
        encodedTodoList: await allDocsMap["todo-db"],
        encodedProjectList: await allDocsMap["project-db"],
        encodedContextList: await allDocsMap["context-db"],
        pouchDBRemoteSyncURI: localStorage.getItem("pouchdb.remote-sync-uri") || "",
        firebaseAppAttributes: firebaseConfig.appAttributes,
        developmentMode: developmentMode
    }
    const Elm = require("elm/Main.elm")
    const app = Elm["Main"]
        .embed(document.getElementById("elm-app-container"), flags)


    app.ports["syncWithRemotePouch"].subscribe(async (uri) => {
        localStorage.setItem("pouchdb.remote-sync-uri", uri)
        _.map(db => db.startRemoteSync(uri, "sgtd2-"))(dbMap)
    })


    app.ports["pouchDBUpsert"].subscribe(async ([dbName, id, doc]) => {
        // console.log("upserting", dbName, doc, id)
        const upsertResult = await dbMap[dbName].upsert(id, doc)
        if (_.F()) {
            console.log("upsertResult", upsertResult)
        }
    });


    Notifications.setup(app).catch(console.error)

    app.ports["focusSelector"].subscribe((selector) => {
        setTimeout(() => {
            requestAnimationFrame(() => {
                $(selector).focus()
            })
        }, 0)
    })

    app.ports["signIn"].subscribe(() => {
        let googleAuth = document.getElementById('google-auth');
        googleAuth
            .signInWithRedirect()
            .then(console.info)
            .catch(console.error)
    })

    app.ports["signOut"].subscribe(() => {
        let googleAuth = document.getElementById('google-auth');
        googleAuth
            .signOut()
            .then(console.info)
            .catch(console.error)
    })

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

/*
 //noinspection JSUnresolvedVariable
 if (!WEB_PACK_DEV_SERVER && 'serviceWorker' in navigator) {
 //noinspection JSUnresolvedVariable
 navigator.serviceWorker.register('/service-worker.js');
 }
 */
