"use strict"

// self.addEventListener('install', function(event) {
//     console.log('Service Worker installing.');
// });
//
// self.addEventListener('activate', function(event) {
//     console.log('Service Worker activating.');
// });


self.addEventListener('notificationclick', function (event) {
    console.log("notification click")
    event.notification.close();
}, false);
