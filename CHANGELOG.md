## Upcoming
* update read me to show build status
* travis - add build dev script 
* remove WEB_PACK_DEV_SERVER flag

## v0.11.1 - 2017-05-18
* travis: deploy to firebase dev and prod
* [fix] use env specific firebase config

## v0.11.0 - 2017-05-18
* [fix] last selected todo border now displays correctly
* [fix] serviceWorker skip waiting in dev mode 
* [refactoring] manually control opening and closing of todo dropdowns
* [fix] last selected todo border now displays correctly
* [fix] todo dropdown done close sometimes: manually control opening and closing of todo dropdowns

## v0.10.1 - 2017-05-16
* storing push token per device id
* send push to all registered token

## v0.10.0 - 2017-05-15
* push notifications always shown for mobile, and for desktop only when no window is open. 
* add new logo
* show logo in notification

## v0.9.4 - 2017-05-14
* add firebase functions to send push notifications 

## v0.9.2 - 2017-05-14
* fixed fcm connection error issue by clearing cloudflare cache. 
  * We should consider hosting on firebase itself.   

## v0.9.0 - 2017-05-13
* deploy docs: by letting firebase messaging use/discover its default sw name.

## v0.6.0 - 2017-05-13
* debug: FCM not working on prod. 

## v0.5.1 - 2017-05-13
* fixed travis build
* storing dependencies in repo. 
  To avoid sudden changes on build server and ensure availability 

## v0.5.0 - 2017-05-13
* debug travis build 

## v0.4.0 - 2017-05-13
* display app version in header

## v0.3.0 - 2017-05-13
* add release tool for changelog and version management. 
