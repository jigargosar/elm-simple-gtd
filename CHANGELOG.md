## Upcoming
* [fix] travis detect release tag only then deploy to prod 

## v0.12.5 - 2017-05-22
* [fix] node version 

## v0.12.4 - 2017-05-22
* travis checking : deploy to firebase prod on when we tag a release 

## v0.12.3 - 2017-05-22
* [fix] npm_bump command exit code based on output containing Error string. since npm_bump does't handle exit status for some reason. and post_bump script starts execution
* npm script to commit docs postbump and deploy to firebase dev.    

## v0.12.2 - 2017-05-22
* [fix] focus on next entity if todos project/context change caused it to move in current view. 

## v0.12.1 - 2017-05-20
* [fix] process changed docs from firebase separately so that dont end up sending them back to firebase.
* [fix] fcm token activation
* [fix] firebase sync infinite upsert bug 

## v0.12.0 - 2017-05-20
* [feature] sync local pouch dbs to firebase on sign in

## v0.11.7 - 2017-05-19
* [fix] todo selection clearing when dropdowns open
* [fix] clear selection on esc only when edit mode is none
* [fix] in paper-input space key should not preventDefault. pD was intended only to stop scrolling on space key

## v0.11.6 - 2017-05-19
* [fix] index.html reverting async code  
 
## v0.11.3 - 2017-05-19
* [fix] add min main-view height so that dropdowns can open downwards
* [fix] add max height to dropdowns and make them scrollable
* making scripts async and booting app on WebComponentsReady 
* [fix] moving scripts at end, so page renders faster 
* [fix] moving scripts at end, so page renders faster 
* [fix] close header menu on item click 
* use sign in with popup and custom google provider to prompt for account selection. 

## v0.11.2 - 2017-05-18
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
