"use strict";

import sound from "./sound"
import Fire from "./fire"
import DB from "./pouchdb-wrapper"
import $ from "jquery"
import _ from "ramda"
import Notifications from "./notifications"
import cryptoRandomString from "crypto-random-string"


//noinspection JSUnresolvedVariable
const isDevelopmentMode = IS_DEVELOPMENT_ENV

window.addEventListener('WebComponentsReady', () => {
    boot().catch(console.error)
});

const env = process.env

console.log("env", env)

const npmPackageVersion = env["npm_package_version"]

async function boot() {
    const deviceId = getOrCreateDeviceId()
    const $elm = $("#elm-app-container")
    $elm.trap();

    $elm.on("keydown", `.entity-list`, e => {
        // console.log(e.keyCode, e.key, e.target, e);

        if (e.target.tagName !== "PAPER-INPUT") {
            // prevent document scrolling
            if (e.key === " "/*space: 32*/ && e.target.tagName !== "PAPER-INPUT") {
                e.preventDefault()
            }
            else if (e.key === "ArrowUp" || e.key === "ArrowDown") {
                e.preventDefault()
            }
        }

    })

    $elm.get(0).addEventListener("keydown", e => {
        const $closest = $(e.target).closest("[data-prevent-default-keys]")
        if ($closest.length === 0)return
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
        developmentMode: isDevelopmentMode,
        appVersion: npmPackageVersion,
        deviceId
    }
    const Elm = require("elm/Main.elm")
    const app = Elm["Main"]
        .embed(document.getElementById("elm-app-container"), flags)

    Fire.setup(app, _.values(dbMap))

    _.mapObjIndexed((db, name) => db.onChange(
        (doc) => {
            // console.log(`app.ports["pouchDBChanges"]:`,name, ":", doc.name || doc.text)
            return app.ports["pouchDBChanges"].send([name, doc])
        }
    ))(dbMap)

    app.ports["syncWithRemotePouch"].subscribe(async (uri) => {
        localStorage.setItem("pouchdb.remote-sync-uri", uri)
        _.map(db => db.startRemoteSync(uri, "sgtd2-"))(dbMap)
    })


    app.ports["pouchDBUpsert"].subscribe(async ([dbName, id, doc]) => {
        dbMap[dbName].upsert(id, doc).catch(console.error)
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
                my: "top",
                at: "top",
                of: "#" + ofId,
                within: "#main-view",
                collision: "none"
            }).find(`[tabindex="0"]`).focus()
        })
    })

    app.ports["focusPaperInput"].subscribe((selector) => {
        console.log("focusPaperInput: selector",selector)
        setTimeout(()=>{
            requestAnimationFrame(()=>{
                // $(".materialize-textarea").each(function () {
                $(selector).each(function () {
                    const $textarea = $(this)
                    console.log($textarea)
                    const originalHeight = $textarea.height()
                    console.log("original height", $textarea.height())
                    $textarea.focus()
                    $textarea.data("original-height", originalHeight);
                    $textarea.data("previous-length", $textarea.val().length);
                    // console.log($textArea)
                    $textarea.trigger('autoresize')
                });

            })
        },0)

        setTimeout(() => {
            requestAnimationFrame(() => {
                const toFocus = document.querySelector(selector)
                // console.log("toFocus", toFocus, document.activeElement)
                /*if (toFocus && document.activeElement !== toFocus) {
                    toFocus.focus()
                } else {
                    // console.log("not focusing")
                }*/
                if (toFocus && toFocus.inputElement) {
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
