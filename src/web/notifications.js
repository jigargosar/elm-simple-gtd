"use strict";
import _ from "ramda"
import sound from "./sound"
import swRegister from "./sw-register"
import firebase from "firebase"

export default {setup: setupNotifications}

async function setupNotifications(fire, app) {
    // console.info("Setting up notification ports and sw registration")
    if (!'serviceWorker' in navigator) {
        console.warn("serviceWorker not found in navigator")
        return
    }

    navigator.serviceWorker.addEventListener('message', event => {
        const data = event.data;
        console.log("JS: serviceWorker.onMessage", event.data, event)
        if (data["firebase-messaging-msg-type"]) {
            // console.info("FBJS: ignoring message event received", data, event)
        } else {
            if (data && data["data"] && data["data"]["notificationClickedPort"]) {
                const replyPort = data["data"]["notificationClickedPort"]
                // console.log("JS: sending to port: ",replyPort, data)
                app.ports[replyPort].send(data)

            } else {
                // console.log("JS: sending to port: notificationClicked ", data)
                app.ports["notificationClicked"].send(data)
            }
        }
    });

    // console.info("navigator.serviceWorker.register: ", swScriptPath)
    const reg = await swRegister

    const messaging = firebase.messaging()
    messaging.useServiceWorker(reg)


    async function getAndSendFCMToken() {
        const fcmToken = await messaging.getToken()
        // console.warn("await messaging.getToken()",fcmToken)
        app.ports["onFCMTokenChanged"].send(fcmToken)
    }

    await getAndSendFCMToken()

    messaging.onTokenRefresh((...args) =>{
        console.warn("onTokenRefresh args:", args)
        return getAndSendFCMToken()
    })

    // app.ports["showTodoReminderNotification"].subscribe(showTodoReminderNotification(reg))

    app.ports["showTodoReminderNotification"].subscribe(showTodoReminderNotification(reg))

    app.ports["closeNotification"].subscribe(closeNotification(reg))

    app.ports["showRunningTodoNotification"].subscribe(showRunningTodoNotification(reg))

}


const closeNotification = reg => async (tag) => {
    const notification = _.find(_.propEq("tag", tag), await reg.getNotifications())
    if (notification) {
        notification.close()
    }
}

const showRunningTodoNotification = reg => async (req) => {
    const permission = await Notification.requestPermission()
    sound.start()
    if (permission !== "granted") return
    reg.showNotification(req.title, {
        tag: req.tag,
        requiresInteraction: true,
        sticky: true,
        renotify: true,
        vibrate: [500, 110, 500, 110, 450, 110, 200, 110, 170, 40, 450, 110, 200, 110, 170, 40, 500],
        sound: "/alarm.ogg",
        icon: "/logo.png",
        actions: req.actions,
        body: req.body,
        data: req.data
    })
}

// const showNotification = (fire, reg) => async ([uid, connected, msg]) => {
const showTodoReminderNotification = reg => async (msg) => {
    const {tag, title, data} = msg

    const permission = await Notification.requestPermission()
    if (permission !== "granted") return
    reg.showNotification("", {
        tag,
        requiresInteraction: true,
        sticky: true,
        renotify: true,
        vibrate: [500, 110, 500, 110, 450, 110, 200, 110, 170, 40, 450, 110, 200, 110, 170, 40, 500],
        sound: "/alarm.ogg",
        icon: "/logo.png",
        actions: [
            {title: "Mark Done", action: "mark-done"},
            {title: "Snooze", action: "snooze"},
        ],
        body: title,
        data
    })
    // }
}

