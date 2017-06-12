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
        promiseList.push(clients.then(sendPush(notificationData)))
    })
    return Promise.all(promiseList)
}

const sendPush = notificationData => clients => {
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


// exports.onNotify =
//     functions
//         .database.ref("/users/{uid}/notify/{tag}")
//         .onWrite(event =>{
//             const oldData = event.data.previous.val();
//             const newData = event.data.val()
//             const uid = event.params["uid"]
//
//             if (!oldData && newData || oldData && newData && oldData.timestamp < newData.timestamp) {
//                 return getUserClients(uid).then(sendPush(newData))
//             }
//         })


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
                        .then(sendPush(notificationData))
                }


            }

        })

function updateNotificationWithTimestamp(uid, todoId, timestamp) {
    const notificationPath = `/notifications/${uid}---${todoId}`
    const ref = admin.database().ref(notificationPath)
    if (timestamp) {
        const notificationValue = {uid,todoId, timestamp}
        console.log("write: ", notificationPath, notificationValue)
        return ref.set(notificationValue)
    } else {
        const notificationValue = null
        console.log("write: ", notificationPath, notificationValue)
        return ref.set(notificationValue)
    }
}

exports.updateNotificationOnTodoChanged =
    functions
        .database.ref("/users/{uid}/todo-db/{todoId}")
        .onWrite(event => {
            const eventSnapShot = event.data
            const uid = event.params["uid"]
            const todoId = event.params["todoId"]

            console.log(eventSnapShot.current.val(), eventSnapShot.previous.val())

            const timestampSnapShot = eventSnapShot.child("reminder/at")
            if (timestampSnapShot.changed()) {
                return updateNotificationWithTimestamp(uid, todoId, timestampSnapShot.val())
            }else{
                console.log("reminder snapshot didn't change, not performing any write.", timestampSnapShot.val())
            }
        })
