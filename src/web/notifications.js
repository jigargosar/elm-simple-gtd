"use strict";
import _ from "ramda"
import sound from "./sound"
import swRegister from "./sw-register"

export default {setup: setupNotifications}

async function setupNotifications(fire, app) {
    // console.info("Setting up notification ports and sw registration")
    if (!'serviceWorker' in navigator) {
        console.warn("serviceWorker not found in navigator")
        return
    }

    navigator.serviceWorker.addEventListener('message', event => {
        const data = event.data;
        // console.log("JS: serviceWorker.onMessage", event.data, event)
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

    const intervalId = setInterval(() => {
        let messaging = document.getElementById("fb-messaging");
        if (!messaging) {
            // console.warn(`document.getElementById("fb-messaging")`, messaging)
            return
        }
        console.debug("messaging.activate(reg)")
        messaging.activate(reg)
        clearTimeout(intervalId);
    }, 100)


    app.ports["showTodoReminderNotification"].subscribe(showTodoReminderNotification(fire, reg))

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
const showTodoReminderNotification = (fire, reg) => async (msg) => {
    const {tag, title, data} = msg
    /*
     console.info(connected, msg)
     const notifyMsg = {
     todoId: tag, tag, title, uid, timestamp:Date.now(),serverTimestamp: firebase.database.ServerValue.TIMESTAMP
     }

     if (connected) {
     // fetch("https://us-central1-rational-mote-664.cloudfunctions.net/notificationCorn", {mode:"no-cors"})
     //     .then(console.warn)
     //     .catch(console.error)

     fire
     .ref(`/users/${uid}/notify/${tag}`)
     .set(notifyMsg)


     // $.get('https://us-central1-rational-mote-664.cloudfunctions.net/sendPush', msg)
     //  .then(console.warn)
     //  .catch(console.error)

     } else {*/
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

