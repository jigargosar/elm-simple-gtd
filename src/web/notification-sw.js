// self.importScripts("./common.js")

// self.addEventListener('fetch', function (event) {
//     // console.log("sw:fetch listener event",event, event.request.url)
// })

// self.addEventListener('install', function (event) {
//     // event.waitUntil(self.skipWaiting())
// })

self.addEventListener('notificationclick', function (event) {
    // console.log("notification click", event)
    // event.notification.close();

    event.waitUntil(
        clients
            .matchAll({type: "window"})
            .then(function (clientList) {
                for (var i = 0; i < clientList.length; i++) {
                    const client = clientList[i]
                    postMessage(client, event)
                    if (client.focus) {
                        return client.focus();
                    }
                }
                if (clients.openWindow) {
                    return clients
                    // .openWindow(url)
                        .openWindow("/")
                        .then(function (client) {
                            setTimeout(function () {
                                postMessage(client, event)
                            }, 2000)
                        })
                }
            })
    );

}, false);

function postMessage(client, event) {
    console.log("posting notification-clicked from event", event)
    client.postMessage({
        type: "notification-clicked",
        action: event.action,
        data: event.notification.data
    })
}


// Give the service worker access to Firebase Messaging.
// Note that you can only use Firebase Messaging here, other Firebase libraries
// are not available in the service worker.
importScripts('https://www.gstatic.com/firebasejs/3.9.0/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/3.9.0/firebase-messaging.js');

// Initialize the Firebase app in the service worker by passing in the
// messagingSenderId.
firebase.initializeApp({
    'messagingSenderId': '476064436883'
});

// Retrieve an instance of Firebase Messaging so that it can handle background
// messages.
// const messaging = firebase.messaging();

// Handle incoming messages. Called when:
// - a message is received while the app has focus
// - the user clicks on an app notification created by a sevice worker
//   `messaging.setBackgroundMessageHandler` handler.
// messaging.onMessage(function(payload) {
//     console.log("Message received. ", payload);
//     // ...
// });


self.addEventListener('push', function(event) {
    console.log('[Service Worker] Push Received.');
    console.log(`[Service Worker] Push had this data: "${event.data.text()}"`, event.data);

    const title = 'Push Codelab';
    const options = {
        body: 'Yay it works.',
        sound: "/alarm.ogg",
        timestamp:0
    };

    event.waitUntil(self.registration.showNotification(title, options));
});


// messaging.setBackgroundMessageHandler(function (payload) {
//     console.log('[firebase-messaging-sw.js] Received background message ', payload);
//     // Customize notification here
//     const notificationTitle = 'Hurray Custom notification';
//     const notificationOptions = {
//         requiresInteraction: true,
//         sticky: true,
//         renotify: true,
//         tag: payload.data.id,
//         vibrate: [500, 110, 500, 110, 450, 110, 200, 110, 170, 40, 450, 110, 200, 110, 170, 40, 500],
//         sound: "/alarm.ogg",
//         actions: [
//             {title: "Mark Done", action: "mark-done"},
//             {title: "Snooze", action: "snooze"},
//         ],
//         body: 'setting body: received data: ' + JSON.stringify(payload.data),
//         data: payload.data
//     };
//
//     return self.registration.showNotification(notificationTitle,
//         notificationOptions);
// });
