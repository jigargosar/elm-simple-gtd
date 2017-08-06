import "babel-polyfill"

import PouchDB from "pouchdb-browser"

//noinspection JSUnresolvedVariable
if (WEBPACK_DEV_SERVER) {
  self.addEventListener('install', function (event) {
    console.log("calling skipWaiting")
    return self.skipWaiting()
  })
  self.addEventListener('activate', function (event) {
    console.log("calling claim")
    return self.clients.claim()
  })
}

let extracted = async function (event, skipFocus) {
  const clientList = await clients.matchAll({type: "window"})
  const client = clientList[0]
  if (client) {
    postMessage(client, event)
    if (!skipFocus && client.focus) {
      return client.focus()
    }
  } else {
    if (clients.openWindow) {
      return clients
      // .openWindow(url)
          .openWindow("#!/contexts")
          .then(function (client) {
            setTimeout(function () {
              postMessage(client, event)
            }, 2000)
          })
    }
  }
  
}
self.addEventListener('notificationclick', function (event) {
  // console.log("notification click", event)
  // event.notification.close();
  const skipFocusActionList = (event.notification.data && event.notification.data.skipFocusActionList)
      ? event.notification.data.skipFocusActionList
      : []
  const skipFocus = skipFocusActionList.findIndex(action => action === event.action) >= 0
  
  event.waitUntil(extracted(event, skipFocus));
  
}, false);

function postMessage(client, event) {
  // console.log("posting notification-clicked from event", event)
  client.postMessage({
    type: "notification-clicked",
    action: event.action,
    data: event.notification.data,
  })
}


// Give the service worker access to Firebase Messaging.
// Note that you can only use Firebase Messaging here, other Firebase libraries
// are not available in the service worker.
importScripts(
    'https://www.gstatic.com/firebasejs/3.9.0/firebase-app.js',
    'https://www.gstatic.com/firebasejs/3.9.0/firebase-messaging.js',
    // 'bower_components/pouchdb/dist/pouchdb.js',
    // 'browser-detect.min.js',
    // 'bower_components/pouchdb/dist/pouchdb.find.js',
);


function isMobile() {
  return self.navigator.userAgent.match(/.*Mobi.*/i)
  // const result = browser(self.navigator.userAgent)
  // console.log(result);
  // return result.mobile
}

// Initialize the Firebase app in the service worker by passing in the
// messagingSenderId.
firebase.initializeApp({
  'messagingSenderId': '476064436883',
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


function displayNotification(event) {
  try {
    const data = event.data.json().data
    console.log(`[notification-sw] displaying notification `, data)
    const todoId = data.todoId
    data.id = todoId
    
    const todoDB = new PouchDB("todo-db")
    
    return todoDB
        .get(todoId)
        .then(todo => {
          console.log("pdb found todo", todo)
          
          const title = "";
          const notificationOptions = {
            requiresInteraction: true,
            sticky: true,
            renotify: true,
            tag: data.id,
            vibrate: [500, 110, 500, 110, 450, 110, 200, 110, 170, 40, 450, 110, 200, 110, 170, 40, 500],
            sound: "/alarm.ogg",
            icon: "/logo.png",
            actions: [
              {title: "Mark Done", action: "mark-done"},
              {title: "Snooze", action: "snooze"},
            ],
            body: todo.text,
            data,
            timestamp: data.timestamp,
          };
          return self.registration.showNotification(title, notificationOptions);
        })
  } catch (e) {
    console.warn(e);
    const title = 'Push Codelab';
    const options = {
      body: 'Yay it works.',
      sound: "/alarm.ogg",
      timestamp: 0,
    };
    return self.registration.showNotification(title, options);
  }
}

self.addEventListener('push', function (event) {
  console.log(`[notification-sw] Push received. event.data.text(): `, event.data.text())
  
  return event.waitUntil(displayNotification(event))
  
  // event.waitUntil(clients
  //     .matchAll({type: "window"})
  //     .then(function (clientList) {
  //         if (clientList.length === 0 || isMobile()) {
  //             return displayNotification(event)
  //         } else {
  //             console.warn(
  //                 "not displaying notification since we detected an controlled browser window and non-mobile
  // browser") } }))
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
