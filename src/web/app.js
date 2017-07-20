import "./vendor"
import sound from "./sound"
import Fire from "./fire"
import DB from "./db"
import $ from "jquery"
import _ from "ramda"
import Notifications from "./notifications"
import cryptoRandomString from "crypto-random-string"
import autosize from "autosize"
import localforage from "localforage"
import MutationSummary from "mutation-summary"
import Kefir from "kefir"

// noinspection NpmUsedModulesInstalled
import {Main} from "elm/Main.elm"

//noinspection JSUnresolvedVariable
const isDevelopmentMode = process.env["NODE_ENV"] === "development"
const env = process.env
const npmPackageVersion = env["npm_package_version"]

//test

/*global.xhot = module.hot

 if(module.hot){
 module.hot.addStatusHandler(status => {
 console.warn("hot status", status);
 })
 }*/

const observer = new MutationSummary({
    callback: summaries => {
        // console.log(summaries)

        const autoFocusSummary = summaries[0]
        $(autoFocusSummary.added).first().focus()
        console.log(autoFocusSummary.added)
    },
    queries: [{element: ".auto-focus"}],
})

window.appBoot = async function appBoot() {
    const deviceId = getOrCreateDeviceId()
    const isFirstVisit = getOrCreateFirstVisit()
    const $elm = $("#elm-container")
    // $elm.trap();

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


    Kefir.merge(
        [Kefir.fromEvents($elm.get(0), "focusin"),
         Kefir.fromEvents($elm.get(0), "focusout"),
        ],
         )
         .debounce(100)
         .filter(_.propEq("type", "focusout"))
         .log()
         .observe({value(){
             requestAnimationFrame(()=>{
                 $(".entity-list .focusable-list-item[tabindex=0]").first().focus()
             })
         }})


    $elm.get(0).addEventListener("keydown", e => {
        const $closest = $(e.target).closest("[data-prevent-default-keys]")
        if ($closest.length === 0) return
        const preventDefaultKeys =
            $closest.data("prevent-default-keys").split(",")
        // console.log(e.keyCode, e.key, e, preventDefaultKey);

        if (_.contains(e.key)(preventDefaultKeys)) {
            e.preventDefault()
        }
    }, true)

    const db = await DB()

    const store = localforage.createInstance({
        name: "SimpleGTD.com offline store",
    });

    const localPref = await store.getItem("local-pref")


    const flags = _.merge({
        now: Date.now(),
        // encodedTodoList: await allDocsMap["todo-db"],
        // encodedProjectList: await allDocsMap["project-db"],
        // encodedContextList: await allDocsMap["context-db"],
        // encodedTodoList: [],
        // encodedProjectList: [],
        // encodedContextList: [],
        pouchDBRemoteSyncURI: localStorage.getItem("pouchdb.remote-sync-uri") || "",
        developmentMode: isDevelopmentMode,
        appVersion: npmPackageVersion,
        deviceId,
        config: {isFirstVisit, deviceId, npmPackageVersion, isDevelopmentMode},
        localPref: localPref,
    }, db.allDocsMap)


    const app = Main
        .embed(document.getElementById("elm-container"), flags)


    const fire = Fire.setup(app, _.values(db.list), deviceId)

    db.setupApp(app)

    app.ports["persistLocalPref"].subscribe(async (localPref) => {
        store.setItem("local-pref", localPref)
             .catch(console.error)
    });


    Notifications.setup(fire, app).catch(console.error)

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

    app.ports["positionPopupMenu"].subscribe((ofSelector) => {
        requestAnimationFrame(() => {
            const $popup = $("#popup-menu")
            $popup.position({
                my: "right top",
                at: "right top",
                of: $(ofSelector),
                within: ".overlay",
                collision: "fit",
            })
            $popup.find(".auto-focus").first().focus()

            const focusableSelector = ":focusable, input:focusable"
            $popup.on("keydown", focusableSelector, function (e) {
                if (e.key !== "Tab") return
                const $focusable = $popup.find(focusableSelector)

                const first = $focusable.first().get(0)
                const last = $focusable.last().get(0)
                const dateTimeInputSelector = `input[type="date"], input[type="time"]`

                if (e.shiftKey) {

                    if (this === first) {
                        e.preventDefault()
                        e.stopPropagation()
                        last.focus()
                    } else if ($(this).is(dateTimeInputSelector)) {
                        e.preventDefault()
                        e.stopPropagation()
                        $focusable.get($.inArray(this, $focusable) - 1).focus()
                    }
                }
                else {


                    if (this === last) {
                        e.preventDefault()
                        e.stopPropagation()
                        first.focus()
                    } else if ($(this).is(dateTimeInputSelector)) {
                        e.preventDefault()
                        e.stopPropagation()
                        $focusable.get($.inArray(this, $focusable) + 1).focus()
                    }
                }
            })
        })
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

function getOrCreateFirstVisit() {
    let firstVisit = localStorage.getItem("first-visit")
    if (!firstVisit) {
        localStorage.setItem("first-visit", "false")
    }
    return !!firstVisit
}
