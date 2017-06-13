"use strict"

const functions = require('firebase-functions')
const admin = require("firebase-admin")
const _ = require("ramda")

admin.initializeApp(functions.config().firebase);

const second = 1000
const minute = 60 * second
const tenMinutes = 10 * minute
const fiveMinutes = 5 * minute

exports.testPush = functions.https.onRequest((req, res) => {
    // admin.database().ref('/messages').push({original: original}).then(snapshot => {
    //     // Redirect with 303 SEE OTHER to the URL of the pushed object in the Firebase console.
    //     res.redirect(303, snapshot.ref);
    // });
    return admin.database().ref("/users").once("value")
                .then(sendTestPushToAllUsersWithRegistrationToken)
                .then(arr => res.json(arr))

});

function sendTestPushToAllUsersWithRegistrationToken(userMap) {
    const promiseList = []
    userMap.forEach(function (userEntry) {
        const userId = userEntry.key
        const userData = userEntry.val()
        if (userData.token) {
            const promise = admin
                .messaging()
                .sendToDevice(
                    userData.token,
                    {
                        data: {
                            todoId: "7aIPoEclCGfR6lPUXb71hGXdoETwthsaETqSK98Bne2qyw2uWJcTgKDj03lpPCDt",
                            uid: userId,
                            timestamp: Date.now() + ""
                        }
                    },
                    {timeToLive: tenMinutes, priority: "high"}
                )
            promiseList.push(promise)
        }
    })
    return Promise.all(promiseList)
}


exports.notificationCorn = functions.https.onRequest((req, res) => {
    return admin
        .database().ref("/notifications")
        .orderByChild("timestamp")
        .endAt(Date.now() + fiveMinutes)
        .once("value")
        .then(sendPushNotifications)
        .then(arr => {
            console.log(arr)
            return res.json(arr)
        })
})


function getUserTokenMap(uid) {
    return admin.database().ref("/users/" + uid + "/tokens").once("value")
                .then(getMapFromSnapshot)
}

function getUserClients(uid) {
    return admin.database().ref("/users/" + uid + "/clients").once("value")
                .then(getMapFromSnapshot)
                .then(_.values)
}

function getMapFromSnapshot(snapshot) {
    const map = {}
    snapshot.forEach(entry => {
        map[entry.key] = entry.val()
    })
    return map;
}

function sendPushNotifications(notificationMap) {
    const getUserClientsMemo = _.memoize(getUserClients)
    const promiseList = []
    notificationMap.forEach(notificationEntry => {
        const notificationData = notificationEntry.val()
        const uid = notificationData.uid
        const clients = getUserClientsMemo(uid)
        promiseList.push(clients.then(sendNotificationToClients(notificationData)))
    })
    return Promise.all(promiseList)
}

const sendNotificationToClients = notificationData => clients => {
    console.log("clients", clients)
    const {todoId, timestamp, uid} = notificationData

    function sendPushForClient(client) {
        if (client.connected) {
            console
                .log("ignoring push for connected client"
                    , notificationData
                    , client)

            return Promise.resolve({
                msg: "ignoring push for connected client", client, notificationData
            })
        }

        return admin
            .messaging()
            .sendToDevice(
                client.token,
                {data: {todoId, timestamp: "" + timestamp, uid}},
                {timeToLive: tenMinutes, priority: "high"}
            )
            .then(mdRes => {
                const tokenUnregistered = mdRes.results.find(mdResult => {
                    return mdResult.error && mdResult.error.code === "messaging/registration-token-not-registered"
                })
                if (tokenUnregistered) {
                    return deleteToken(uid, client.id)
                        .then(res => ({error: {mdRes, deleteTokenRes: res}}))
                }
                return mdRes
            })
    }

    return Promise.all(_.map(sendPushForClient, clients))
}

function deleteToken(uid, deviceId) {
    return admin.database().ref(`/users/${uid}/clients/${deviceId}/token`).set(null)
}


const sendNotification = data =>
    getUserClients(data.uid)
        .then(sendNotificationToClients(data))

exports.onTodoUpdated =
    functions
        .database.ref("/users/{uid}/todo-db/{todoId}")
        .onWrite(event => {
            const oldTodo = event.data.previous.val();
            const newTodo = event.data.val()
            const uid = event.params["uid"]
            const todoId = event.params["todoId"]

            if (oldTodo && newTodo) {
                // todo was updated
                if (oldTodo.dueAt && newTodo.dueAt
                    && oldTodo.dueAt === newTodo.dueAt
                    && oldTodo.reminder && oldTodo.reminder.at
                    && newTodo.reminder && newTodo.reminder.at
                    && oldTodo.reminder.at !== newTodo.reminder.at
                ) {
                    const timestamp = oldTodo.reminder.at
                    //todo was snoozed
                    const notificationData = {uid, timestamp, todoId}
                    return getUserClients(uid)
                        .then(sendNotificationToClients(notificationData))
                }


            }

        })

const createRef = path => admin.database().ref(path)

const write = _.curry((value, refOrPath) => {
    const ref = _.when(_.is(String), createRef)(refOrPath)
    console.log("write: ref = ", ref.toString(), "value = ", value)
    return ref.set(value)
})

const writeAt = _.flip(write)

const removeAt = write(null)

const notificationPath = (uid, todoId) => `/notifications/${uid}---${todoId}`

const conditionalPromise = (fn, bool) => bool ? fn() : Promise.resolve()

function addNotification(uid, todoId, newTimestamp, shouldSendPush) {
    const writeNotification = writeAt(notificationPath(uid, todoId))
    const notificationData = {uid, todoId, newTimestamp}
    return conditionalPromise(_ => sendNotification(notificationData), shouldSendPush)
        .then(_ => writeNotification(notificationData))
}


const shouldDeleteNotification = (eventSnapShot) => {
    const doneSnapshot = eventSnapShot.child("done")
    const deletedSnapshot = eventSnapShot.child("deleted")
    const timestampSnapShot = eventSnapShot.child("reminder/at")
    return (doneSnapshot.changed() && doneSnapshot.val() === true)
           || (deletedSnapshot.changed() && doneSnapshot.val() === true)
           || (timestampSnapShot.changed() && timestampSnapShot.val() === null)
}
exports.updateNotificationOnTodoChanged =
    functions
        .database.ref("/users/{uid}/todo-db/{todoId}")
        .onWrite(event => {
            const eventSnapShot = event.data
            const uid = event.params["uid"]
            const todoId = event.params["todoId"]

            console.log(eventSnapShot.current.val(), eventSnapShot.previous.val())

            if (shouldDeleteNotification(eventSnapShot)) {
                return removeAt(notificationPath(uid, todoId))
            }

            const timestampSnapshot = eventSnapShot.child("reminder/at")
            if (timestampSnapshot.changed()) {
                const shouldTriggerPush = _.not(eventSnapShot.child("dueAt").changed())
                return addNotification(
                    uid, todoId,
                    timestampSnapshot.val(),
                    shouldTriggerPush
                )
            }
        })
