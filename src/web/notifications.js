"use strict";
import _ from "ramda"
import $ from "jquery"

export default {setup: setupNotifications}

async function setupNotifications(fire, app) {
    console.info("Setting up notification ports and sw registration")
    if (!'serviceWorker' in navigator) {
        console.warn("serviceWorker not found in navigator")
        return
    }

    const swScriptPath = IS_DEVELOPMENT_ENV ? "/notification-sw.js" : '/service-worker.js'
    // const swScriptPath = "/notification-sw.js"

    navigator.serviceWorker.addEventListener('message', event => {
        const data = event.data;
        console.log("MJS: serviceWorker.onMessage", event.data, event)
        if (data["firebase-messaging-msg-type"]) {
            console.info("FBJS: ignoring message event received", data, event)
        } else {
            app.ports["notificationClicked"].send(data)
        }
    });

    console.info("navigator.serviceWorker.register: ", swScriptPath)
    const reg = await navigator.serviceWorker.register(swScriptPath)

    const intervalId = setInterval(() => {
        let messaging = document.getElementById("fb-messaging");
        if (!messaging) {
            console.warn(`document.getElementById("fb-messaging")`, messaging)
            return
        }
        console.debug("messaging.activate(reg)")
        messaging.activate(reg)
        clearTimeout(intervalId);
    }, 100)


    app.ports["showNotification"].subscribe(showNotification(fire, reg))
    app.ports["closeNotification"].subscribe(closeNotification(reg))

}


const closeNotification = reg => async (tag) => {
    const notification = _.find(_.propEq("tag", tag), await reg.getNotifications())
    if (notification) {
        notification.close()
    }
}

const showNotification = (fire, reg) => async ([uid, connected, msg]) => {
    console.info(connected, msg)
    const {tag, title, data} = msg
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

    } else {
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
    }
}

const authenticatedRequest = function (method, url, body) {

    if (!firebase.auth().currentUser) {
        throw new Error('Not authenticated. Make sure you\'re signed in!');
    }

    // Get the Firebase auth token to authenticate the request
    return firebase.auth().currentUser.getToken().then(function (token) {
        const request = {
            method: method,
            url: url,
            dataType: 'json',
            beforeSend: function (xhr) { xhr.setRequestHeader('Authorization', 'Bearer ' + token); }
        }

        if (method === 'POST') {
            request.contentType = 'application/json'
            request.data = JSON.stringify(body);
        }

        console.log('Making authenticated request:', method, url);
        return $.ajax(request).catch(function () {
            throw new Error('Request error: ' + method + ' ' + url);
        });
    });
};
