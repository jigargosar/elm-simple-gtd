import "./vendor"
import sound from "./sound"
import Fire from "./fire"
import DB from "./db"
import $ from "jquery"
import _ from "ramda"
import Notifications from "./notifications"
import cryptoRandomString from "crypto-random-string"
// import autosize from "autosize"
import localforage from "localforage"
import MutationSummary from "mutation-summary"
import {Kefir} from "kefir"

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

const mutationObserverFocusSelectorStream = Kefir.stream(emitter => {
  
  const focusableEntityListItemSelector = ".focusable-list-item[tabindex=0]"
  const autoFocusSelector = ".auto-focus"
  const observer = new MutationSummary({
    callback: summaries => {
      // console.log(summaries)
      
      const autoFocusSummaryAdded = summaries[0].added
      if (!_.isEmpty(autoFocusSummaryAdded)) {
        //note: delaying auto-focus to ensure that it takes priority.
        setTimeout(() => emitter.emit(".auto-focus"), 0)
      }
      
      const focusInEntitySummary = summaries[1]
      const focusInEntitySummaryAdded = focusInEntitySummary.added
      if (!_.isEmpty(focusInEntitySummaryAdded)) {
        // console.log("focusInEntitySummary.added", focusInEntitySummaryAdded)
        emitter.emit(".focusable-list-item[tabindex=0]")
      }
    },
    queries: [{element: autoFocusSelector},
      {element: focusableEntityListItemSelector},
    ],
  })
})

window.appBoot = async function appBoot(elmMain = Main) {
  
  const deviceId = getOrCreateDeviceId()
  const $elm = $("#elm-container")
  // $elm.trap();
  
  $elm.on("keydown", `.entity-list`, e => {
    // console.log(e.keyCode, e.key, e.target, e);
    
    // prevent document scrolling
    if (e.key === " " || e.key === "ArrowUp" || e.key === "ArrowDown") {
      e.preventDefault()
    }
    
  })
  
  
  const db = await DB()
  
  const store = localforage.createInstance({
    name: "SimpleGTD.com offline store",
  });
  
  const localPref = await store.getItem("local-pref")
  
  
  const debugSecondMultiplier = (() => {
    if (WEBPACK_DEV_SERVER) {
      return 1
    } else {
      return 1
    }
  })()
  
  const flags = _.merge({
    now: Date.now(),
    pouchDBRemoteSyncURI: localStorage.getItem("pouchdb.remote-sync-uri") || "",
    developmentMode: isDevelopmentMode,
    appVersion: npmPackageVersion,
    deviceId,
    config: {debugSecondMultiplier, deviceId, npmPackageVersion, isDevelopmentMode},
    localPref: localPref,
  }, db.allDocsMap)
  
  
  const app = elmMain
      .embed(document.getElementById("elm-container"), flags)
  
  
  const fire = Fire.setup(app, _.values(db.list), deviceId)
  
  db.setupApp(app)
  
  app.ports["persistLocalPref"].subscribe(async (localPref) => {
    store.setItem("local-pref", localPref)
         .catch(console.error)
  });
  
  
  Notifications.setup(fire, app).catch(console.error)
  
  const portFocusSelectorStream =
      Kefir.stream(emitter => {
        app.ports["focusSelector"].subscribe((selector) => {
          // console.log("port: focusSelector received selector", selector)
          emitter.emit(selector)
        })
      })
  
  const addMetadataToFocusSelectorStream =
      (stream, streamName) => stream.map(selector => ({streamName, selector}))
  
  const focusSelectorStreams =
      [addMetadataToFocusSelectorStream(
          portFocusSelectorStream,
          "portFocusSelectorStream",
      ),
       addMetadataToFocusSelectorStream(
           mutationObserverFocusSelectorStream,
           "mutationObserverFocusSelectorStream",
       )]
  Kefir.merge(focusSelectorStreams)
       .observe({
         value(options) {
           const $toFocus = $(options.selector).first()
      
           // console.log("[Kefir] focusSelector", _.merge(options, {
           // dataKey: $toFocus.data("key"),
           // }))
      
           $toFocus.focus()
         },
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
