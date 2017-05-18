"use strict";

const _ = require("ramda")

const firebaseDevConfig = {
    apiKey: "AIzaSyASFVPlWjIrpgSlmlEEIMZ0dtPFOuRC0Hc",
    authDomain: "rational-mote-664.firebaseapp.com",
    databaseURL: "https://rational-mote-664.firebaseio.com",
    projectId: "rational-mote-664",
    storageBucket: "rational-mote-664.appspot.com",
    messagingSenderId: "49437522774"
}

const firebaseProdConfig = {
    apiKey: "AIzaSyDgqOiOMuTvK3PdzJ0Oz6ctEg-devcgZYc",
    authDomain: "simple-gtd-prod.firebaseapp.com",
    databaseURL: "https://simple-gtd-prod.firebaseio.com",
    projectId: "simple-gtd-prod",
    storageBucket: "simple-gtd-prod.appspot.com",
    messagingSenderId: "1061254169900"
}

//noinspection JSUnresolvedVariable
const firebaseConfig =
    IS_DEVELOPMENT_ENV ? firebaseDevConfig : firebaseProdConfig


const firebaseApp = firebase.initializeApp(firebaseConfig);

const cryptoRandomString = require('crypto-random-string');

require("./pcss/main.pcss")


const sound = require("./sound")
const $ = require("jquery")
window.jQuery = $
require("./jquery.trap")
require("jquery-ui/ui/position")
const Notifications = require("./notifications")
import DB from "./pouchdb-wrapper"


const developmentMode = IS_DEVELOPMENT_ENV
const pkg = packageJSON

boot().catch(console.error)
async function boot() {
    const deviceId = getOrCreateDeviceId()
    const $elm = $("#elm-app-container")
    $elm.trap();

    $elm.on("keydown", `.todo-item, .entity-item`, e => {
        // console.log(e.keyCode, e.key, e);
        if (e.key === " "/*space: 32*/) {
            e.preventDefault()
        }
    })

    $elm.get(0).addEventListener("keydown", e => {
        const $closest = $(e.target).closest("[data-prevent-default-keys]")
        if($closest.length===0)return
        const preventDefaultKeys =
            $closest.data("prevent-default-keys").split(",")
        // console.log(e.keyCode, e.key, e, preventDefaultKey);

        if (_.contains(e.key)(preventDefaultKeys)) {
            e.preventDefault()
        }
    }, true)

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
        // encodedTodoList: [],
        // encodedProjectList: [],
        // encodedContextList: [],
        pouchDBRemoteSyncURI: localStorage.getItem("pouchdb.remote-sync-uri") || "",
        developmentMode: developmentMode,
        appVersion: pkg.version,
        deviceId
    }
    const Elm = require("elm/Main.elm")
    const app = Elm["Main"]
        .embed(document.getElementById("elm-app-container"), flags)


    _.mapObjIndexed((db, name) => db.onChange(
        (doc) =>
            // console.log(name, ":", doc.name || doc.text)
            app.ports["pouchDBChanges"].send([name, doc])
    ))(dbMap)

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
        // setTimeout(() => {
        requestAnimationFrame(() => {
            // note - we blur here so that view scrolls to element if it already had focus
            $(selector).blur().focus()
        })
        // }, 0)
    })

    app.ports["focusSelectorIfNoFocus"].subscribe((selector) => {
        const $focus = $(":focus, [focused]")
        // console.log($focus, $focus.length)
        if ($focus.length === 0) {
            $(selector).focus()
        }
    })

    app.ports["positionDropdown"].subscribe(([myId, ofId]) => {
        requestAnimationFrame(() => {
            $("#" + myId).position({
                my: "right top",
                at: "right top",
                of: "#" + ofId,
                within: "#main-view",
                collision: "flipfit"
            }).find(`[tabindex="0"]`).focus()
        })
    })

    app.ports["signIn"].subscribe(() => {
        let googleAuth = document.getElementById('google-auth');
        googleAuth
            .signInWithRedirect()
            .then(console.info)
            .catch(console.error)
    })


    app.ports["fireDataWrite"].subscribe(([path, value]) => {
        console.log(`firebaseApp.database().ref(path).set(value)`, {path, value})
        const ref = firebaseApp.database().ref(path);
        ref.set(value)
    })

    app.ports["fireDataPush"].subscribe(([path, value]) => {
        console.log(`firebaseApp.database().ref(path).push(value)`, {path, value})
        firebaseApp.database().ref(path).push(value)
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

function getOrCreateDeviceId() {
    let deviceId = localStorage.getItem("device-id")
    if (!deviceId) {
        deviceId = cryptoRandomString(64)
        localStorage.setItem("device-id", deviceId)
    }
    return deviceId
}
/*
 //noinspection JSUnresolvedVariable
 if (!WEB_PACK_DEV_SERVER && 'serviceWorker' in navigator) {
 //noinspection JSUnresolvedVariable
 navigator.serviceWorker.register('/service-worker.js');
 }
 */
