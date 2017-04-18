"use strict"

// self.addEventListener('install', function(event) {
//     console.log('Service Worker installing.');
// });
//
// self.addEventListener('activate', function(event) {
//     console.log('Service Worker activating.');
// });


self.addEventListener('notificationclick', function (event) {
    console.log("notification click", event)
    event.notification.close();


    event.waitUntil(
        clients
            .matchAll({type: "window"})
            .then(function (clientList) {
                for (var i = 0; i < clientList.length; i++) {
                    var client = clientList[i];
                    client.postMessage("notification clicked: client.postMessage")
                    if (client.focus) {
                        return client.focus();
                    }
                }
                if (clients.openWindow) {
                    return clients
                        .openWindow('http://localhost:8020/')
                        .then(client => {
                            client.postMessage("newWindow notification, this never reaches.")
                        })
                }
            })
    );

}, false);
