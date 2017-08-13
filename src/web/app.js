import "./vendor"
import sound from "./sound"
import Fire from "./fire"
import DB from "./db"
import $ from "jquery"
import _ from "ramda"
import Notifications from "./notifications"
import cryptoRandomString from "crypto-random-string"
import localforage from "localforage"
import MutationSummary from "mutation-summary"
import {Kefir} from "kefir"
import {Main} from "elm/Main.elm"

const isDevelopmentMode = process.env["NODE_ENV"] === "development"
const env = process.env
const npmPackageVersion = env["npm_package_version"]

const mutationObserverFocusSelectorStream = Kefir.stream(emitter => {
  
  // const focusableEntityListItemSelector = ".focusable-list-item[tabindex=0]"
  const autoFocusSelector = ".auto-focus"
  new MutationSummary({
    callback: summaries => {
      // console.log(summaries)
      
      const autoFocusSummaryAdded = summaries[0].added
      if (!_.isEmpty(autoFocusSummaryAdded)) {
        //note: delaying auto-focus to ensure that it takes priority.
        setTimeout(() => emitter.emit(".auto-focus"), 0)
      }
    },
    queries: [
      {element: autoFocusSelector},
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
  
  
  const getOfflineStore = async () => {
    const storeKeys = await store.keys()
    const storeValues = await _.compose(
        ps => Promise.all(ps), _.map(k => store.getItem(k)),
    )(storeKeys)
    return _.zipObj(storeKeys, storeValues)
  }
  const initialOfflineStore = await getOfflineStore()
  // console.log(initialOfflineStore)
  
  const flags = {
    now: Date.now(),
    pouchDBRemoteSyncURI: localStorage.getItem("pouchdb.remote-sync-uri") || "",
    developmentMode: isDevelopmentMode,
    encodedLists: db.allDocsMap,
    config: {
      debug: WEBPACK_DEV_SERVER,
      deviceId,
      npmPackageVersion,
      isDevelopmentMode,
      initialOfflineStore,
    },
  }
  
  
  const app = elmMain
      .embed(document.getElementById("elm-container"), flags)
  
  global.__debug__port = cmdString =>
      app.ports["debugPort"].send(cmdString)
  
  const fire = Fire.setup(app, _.values(db.list), deviceId)
  
  db.setupApp(app)
  
  
  app.ports["persistToOfflineStore"].subscribe(([key, value]) => {
    store.setItem(key, value).catch(console.error)
  });
  
  app.ports["focusSelector"].subscribe((selector) => {
    console.log("port: focusSelector: selector", selector)
    let focusSelector = function () {
      const $toFocus = $(selector).first().get(0)
      if ($toFocus) {
        $toFocus.focus()
      } else {
        let timeoutId = null
    
        const observer = new MutationSummary({
          callback: summaries => {
            // console.log(summaries)
        
            const added = summaries[0].added
            if (!_.isEmpty(added)) {
              $(added[0]).focus()
              observer.disconnect()
              clearTimeout(timeoutId)
            }
          },
          queries: [
            {element: selector},
          ],
        })
    
        timeoutId = setTimeout(() => {
          observer.disconnect()
        }, 3000)
      }
    }
    requestAnimationFrame(() => { requestAnimationFrame(focusSelector)})
  });
  
  
  Notifications.setup(fire, app).catch(console.error)
  
  mutationObserverFocusSelectorStream
      .observe({
        value(selector) {
          console.log("mutationObserverFocusSelectorStream: selector", selector)
          $(selector).first().focus()
        },
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
