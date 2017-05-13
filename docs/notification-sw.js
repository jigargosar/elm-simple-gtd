var serviceWorkerOption = {
  "assets": [
    "/main.js",
    "/common.js"
  ]
};
        var url = "https://simplegtd.com/";

        /******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};
/******/
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/
/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId]) {
/******/ 			return installedModules[moduleId].exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			i: moduleId,
/******/ 			l: false,
/******/ 			exports: {}
/******/ 		};
/******/
/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/
/******/ 		// Flag the module as loaded
/******/ 		module.l = true;
/******/
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/
/******/
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;
/******/
/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;
/******/
/******/ 	// identity function for calling harmony imports with the correct context
/******/ 	__webpack_require__.i = function(value) { return value; };
/******/
/******/ 	// define getter function for harmony exports
/******/ 	__webpack_require__.d = function(exports, name, getter) {
/******/ 		if(!__webpack_require__.o(exports, name)) {
/******/ 			Object.defineProperty(exports, name, {
/******/ 				configurable: false,
/******/ 				enumerable: true,
/******/ 				get: getter
/******/ 			});
/******/ 		}
/******/ 	};
/******/
/******/ 	// getDefaultExport function for compatibility with non-harmony modules
/******/ 	__webpack_require__.n = function(module) {
/******/ 		var getter = module && module.__esModule ?
/******/ 			function getDefault() { return module['default']; } :
/******/ 			function getModuleExports() { return module; };
/******/ 		__webpack_require__.d(getter, 'a', getter);
/******/ 		return getter;
/******/ 	};
/******/
/******/ 	// Object.prototype.hasOwnProperty.call
/******/ 	__webpack_require__.o = function(object, property) { return Object.prototype.hasOwnProperty.call(object, property); };
/******/
/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "";
/******/
/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(__webpack_require__.s = 0);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


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

    event.waitUntil(clients.matchAll({ type: "window" }).then(function (clientList) {
        for (var i = 0; i < clientList.length; i++) {
            var client = clientList[i];
            postMessage(client, event);
            if (client.focus) {
                return client.focus();
            }
        }
        if (clients.openWindow) {
            return clients
            // .openWindow(url)
            .openWindow("/").then(function (client) {
                setTimeout(function () {
                    postMessage(client, event);
                }, 2000);
            });
        }
    }));
}, false);

function postMessage(client, event) {
    console.log("posting notification-clicked from event", event);
    client.postMessage({
        type: "notification-clicked",
        action: event.action,
        data: event.notification.data
    });
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


self.addEventListener('push', function (event) {
    console.log('[Service Worker] Push Received.');
    console.log("[Service Worker] Push had this data: \"" + event.data.text() + "\"");

    var title = 'Push Codelab';
    var options = {
        body: 'Yay it works.',
        sound: "/alarm.ogg",
        timestamp: 0
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

/***/ })
/******/ ]);