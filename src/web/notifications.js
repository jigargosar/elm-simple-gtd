"use strict";
import _ from "ramda"
export const setup = setupNotifications

async function setupNotifications(app) {
    console.log("ssssss")
    if (!'serviceWorker' in navigator) {
        console.warn("servieWorker not found in navigator")
        return
    }

    // const swScriptPath = WEB_PACK_DEV_SERVER ? "/notification-sw.js" : '/service-worker.js'
    const swScriptPath = "/notification-sw.js"

    navigator.serviceWorker.addEventListener('message', event => {
        const data = event.data;
        console.log("MJS: serviceWorker.onMessage", event.data, event)
        if(data["firebase-messaging-msg-type"]){
            console.info("FBJS: ignoring message event received", data, event)
        }else{
            app.ports["notificationClicked"].send(data)
        }
    });
    const reg = await navigator.serviceWorker.register(swScriptPath)

    const intervalId = setInterval(()=>{
        let messaging = document.getElementById('fb-messaging');
        if(!messaging) {
            console.log("messaging not found")
            return
        }
        console.log("activating sw")
        messaging.activate(reg)
        clearTimeout(intervalId);
    },2000)


    app.ports["showNotification"].subscribe(showNotification(reg))
    app.ports["closeNotification"].subscribe(closeNotification(reg))

}


const closeNotification = reg => async (tag) => {
    const notification = _.find(_.propEq("tag", tag), await reg.getNotifications())
    if (notification) {
        notification.close()
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

