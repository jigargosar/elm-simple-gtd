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
                        .openWindow(url)
                        .then(function(client) {
                            setTimeout(function () {
                                postMessage(client, event)
                            },2000)
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


// Give the service worker access to Firebase Messaging.
// Note that you can only use Firebase Messaging here, other Firebase libraries
// are not available in the service worker.
importScripts('https://www.gstatic.com/firebasejs/3.9.0/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/3.9.0/firebase-messaging.js');

// Initialize the Firebase app in the service worker by passing in the
// messagingSenderId.
firebase.initializeApp({
    'messagingSenderId': '49437522774'
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
//     ...
// });


messaging.setBackgroundMessageHandler(function(payload) {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);
    // Customize notification here
    const notificationTitle = 'Background Message Title';
    const notificationOptions = {
        body: 'Background Message body.',
        icon: '/firebase-logo.png'
    };

    return self.registration.showNotification(notificationTitle,
        notificationOptions);
});
