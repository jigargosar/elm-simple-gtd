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
        promiseList.push(getUserClientsMemo(uid).then(sendPush(notificationData)))
    })
    return Promise.all(promiseList)
}

const sendPush = notificationData => clients => {
    console.log("clients", clients)
    const {todoId, timestamp, uid} = notificationData

    function sendPushForClient(client) {
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
