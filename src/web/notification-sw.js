"use strict"

//noinspection JSUnresolvedVariable
const url = WEB_PACK_DEV_SERVER ? "http://localhost:8020/" : "https://simplegtd.com/"

self.addEventListener('notificationclick', function (event) {
    // console.log("notification click", event)
    // event.notification.close();

    event.waitUntil(
        clients
            .matchAll({type: "window"})
            .then(function (clientList) {
                for (let i = 0; i < clientList.length; i++) {
                    const client = clientList[i]
                    postMessage(client, event)
                    if (client.focus) {
                        return client.focus();
                    }
                }
                if (clients.openWindow) {
                    return clients
                        .openWindow(url)
                        .then(function(client) {
                            postMessage(client, event)
                        })
                }
            })
    );

}, false);

function postMessage(client, event) {
    client.postMessage({
        type: "notification-clicked",
        action: event.action,
        data: event.notification.data
    })
}
