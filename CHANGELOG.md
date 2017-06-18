## v0.18.41 - 2017-06-18
* fix/use mat icon button instead of iron-icon/paper button
* appDrawer: clicking on group should not collapse it. smart toggle added.

## v0.18.40 - 2017-06-18
* fix bug: clicking on done todo button also triggers edit mode. 

## v0.18.39 - 2017-06-18
* fix bug: show deleted toggle button didn't work as expected. 

## v0.18.38 - 2017-06-18
* use localforage to persist local user pref
  * contexts/projects collapsible state. 

## v0.18.37 - 2017-06-18
* app drawer: make contexts/projects collapsible. 

## v0.18.36 - 2017-06-18
* adding sass loader for configuring material styling options. And perhaps we could use sass to make our styles more modular than what postcss-cssnext has to offer.
* simplify app drawer: use custom styling

## v0.18.35 - 2017-06-17
* fix: edit todo only when selected. by using onMouseDown, instead of onClick event. 

## v0.18.34 - 2017-06-17
* fix: notification cron error
* fix: entity list focus ux

## v0.18.33 - 2017-06-16
* Simplify: first screen. 

## v0.18.32 - 2017-06-16
* press `r` to set schedule/reminder 

## v0.18.31 - 2017-06-16
* remove new todo enter key handling 

## v0.18.30 - 2017-06-16
* click/edit annoyance: workaround: trigger editing on text click, only when item is tav 0 

## v0.18.29 - 2017-06-16
* todo edit mode: get rid of maybe mode and use overlay.

## v0.18.28 - 2017-06-16
* UX: entity-list view grouping 

## v0.18.27 - 2017-06-15
* ExclusiveMode: centralize edit project/context forms
  * cleanup SharedVM

## v0.18.26 - 2017-06-15
* persistence: remove dep on every second update 

## v0.18.25 - 2017-06-14
* fix running todo header UX
* running : add duration to "you are currently working on"

## v0.18.24 - 2017-06-14
* add continue action on tracker notification

## v0.18.23 - 2017-06-14
* custom-sync view: remove paper input
* remove all paper inputs
* remove unnecessary Paper deps

## v0.18.22 - 2017-06-14
* disable input field propagation so as not to trigger global combos  

## v0.18.21 - 2017-06-14
* schedule: switch instead of starting with `s` shortcut 

## v0.18.20 - 2017-06-14
* use Predicate module instead of custom fn in Todo
* replace bin/done views with entity list views.

## v0.18.19 - 2017-06-14
* On-boarding: create default set of entities. 

## v0.18.18 - 2017-06-13
* add visible feedback links 

## v0.18.17 - 2017-06-13
* fix ff errors 

## v0.18.14 - 2017-06-13
* disable local notification triggers for deleted/done items

## v0.18.13 - 2017-06-13
* ff: remove user access to notifications.  

## v0.18.12 - 2017-06-13
* firebase functions : auto notification creation from todo edits.
* firebase functions: merge both todo update triggers
* ff: delete notification if done or deleted
* change schedule model, so that it is easy to check if todo was just snoozed. 

## v0.18.11 - 2017-06-12
* add link to google group 

## v0.18.9 - 2017-06-12
* add r keyboard shortcut to edit todo reminder/schedule
* and change goto running todo shortcut to shift+r 

## v0.18.8 - 2017-06-12
* display version in left header  
* [fix] app header should always show its account menu and toggle sidebar menu icon.  

## v0.18.7 - 2017-06-12
* bug: menu keyboard traversal stopped working 

## v0.18.5 - 2017-06-11
* fix running todo being canceled on update
* edit reminder: get rid of polymer. so that we can add menu and edit date time form
* trap focus in popup menu: fix bug where arrow keys were not moving menu's highlighted item.

## v0.18.4 - 2017-06-11
* revert edit reminder incomplete commits: so as to fix running todo bug.
* bug: on todo changes running todo gets discarded. 


## v0.18.2 - 2017-06-11
* [fix] material font icons http url is not loading, use https. 

## v0.18.0 - 2017-06-10
* [feature] add time tracker for currently working task 

## v0.17.12 - 2017-06-08
* [fix] header display css 

## v0.17.11 - 2017-06-08
* [fix] header to display viewName
* add github and changelog link in account menu 

## v0.17.8 - 2017-06-08
* quick nav: Use g key to go to entity, and for todo, toggle current grouping view 

## v0.17.6 - 2017-06-08
* [fix] bug: new todo cursor jump 

## v0.17.5 - 2017-06-07
* [patch] Replace polymer context/project menus with custom. And style them using mat-css 

## v0.17.3 - 2017-06-06
* [refactoring] extract generic menu code from context and project menus.
* [fix] preselect prj/ctx in menu for todo.

## v0.17.2 - 2017-06-05
* extract schedule model from todo.
* extract record update helpers in Ext.Record
* [fix] arrow key navigation works even when entity list contains two null entities, i.e. same id but different entity type.
* focus model cleanup

## v0.17.1 - 2017-06-04
* [patch]: context/prj : enter key should save form 

## v0.17.0 - 2017-06-04
* [minor] activate launch bar with `/` key for quick access to contexts and project. 

## v0.16.26 - 2017-06-03
* [fix] show list in project view (probably got lost in last refactoring.) 

## v0.16.25 - 2017-06-01
* group entity: re-modeling 
* Consistent sorting   

## v0.16.24 - 2017-06-01
* on create grp entity, switch view to that entity. 

## v0.16.22 - 2017-06-01
* [fix] show all todo content till double new line. 

## v0.16.21 - 2017-06-01
* [fix] entity list: 
    * focus next entity if current entity is no longer visible in current filtered view.
    * otherwise keep it focused post edit; irrespective of its position change, if any.   
* [fix] when auto snoozing todo locally, update notifications too. (ideally notifications should be updated on todo change firebase function, so that we don't have to manage notification persistence to firebase manually. also notification data, if any will be up to date in firebase. Single point of change is better. But todo notification logic will be duplicated. unless we could run existing elm code from firebase functions.)

## v0.16.18 - 2017-05-31
* [fix] firebase: when pouchdb updates in response to an firebase non-local change, don't send that change back to firebase.
    * Also don't send local changes received from firebase listeners to elm.
    * Updates are distinguished based on the deviceId field in all docs. 
    * On every change made locally by user, we set the docs deviceId to that of local. 

## v0.16.17 - 2017-05-30
* [fix] notification: use event.waitUntil to fix bkg processing notification issue 

## v0.16.16 - 2017-05-30
* [fix] notifications: step 2: functions: 
    * ignore push for connected clients.
    * functions: use user clients instead of user tokens to send push
    * functions: add onTodoChanged for pushing notifications, when a todo is snoozed. (this happens only when at least one client is connected and auto snoozes when reminder is due.)
* [fix] schedule notification in firebase, whenever todo changes. 
  * we had to centralize update of todo, and model had to return cmds. Not clean but will work for now.
  * in future we will move this work in firebase functions itself, this will also help us fix updating notifications scheduled when we were offline.

## v0.16.14 - 2017-05-29
* [fix] notifications: step 1: store client info  

## v0.16.13 - 2017-05-29
* completed domain migration to firebase hosting 

## v0.16.12 - 2017-05-28
* start process of migrating simplegtd.com domain to firebase hosting
* [fix] auto-size input

## v0.16.11 - 2017-05-27
* [fix] increasing limit of todo shown on a page to 50, since our grouped views filter by todo count, certain context are not shown at all. 
  * we need to restrict number of todo per group. Perhaps its time for refactoring entity list into tree 

## v0.16.10 - 2017-05-27
* [fix] cursor jump on editing any text field 
    * use materialize css inputs and set defaultValue

## v0.16.0 - 2017-05-27
* travis: simplify firebase token 

## v0.15.0 - 2017-05-26
* [feature] set new todo project/context based on focused entity

## v0.14.0 - 2017-05-26
* [fix] show inbox/null entity when no todo's are found, in contexts/projects view as well 

## v0.13.20 - 2017-05-26
* [fix] show inbox/null entity when no todo's are found 

## v0.13.19 - 2017-05-26
* [fix] on notification done, hide overlay. and handle done click in notification itself. 
 
## v0.13.18 - 2017-05-26
* [fix] always open popups at bottom, its annoying to see them go behind stuff. 

## v0.13.17 - 2017-05-25
* [fix] make notification done work 

## v0.13.16 - 2017-05-25
* [fix] single key action should only trigger when no modifiers are pressed, e.g. cmd+shift+c dev tool shortcut gets triggered when we try to change context with `c` key 

## v0.13.15 - 2017-05-25
* [fix] css color changes that have been lost after node_modules upgrade 

## v0.13.7 - 2017-05-24
* update run/build scripts  

## v0.13.0 - 2017-05-24
* [minor] npm and bower package updates
* [feature] subgroup entity view
* [fix] todo count in subgroup view

## v0.12.8 - 2017-05-22
* travis: fix release deployment syntax error 

## v0.12.6 - 2017-05-22
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
