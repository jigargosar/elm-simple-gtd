"use strict"

const functions = require('firebase-functions')
const admin = require("firebase-admin")

admin.initializeApp(functions.config().firebase);

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
exports.helloWorld = functions.https.onRequest((req, res) => {
    res.send("Hello from Firebase!");
});

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
                .then(arr => res.send(arr))

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
            return res.send(arr)
        })

})

function sendPushNotifications(notificationMap) {
    const promiseList = []
    notificationMap.forEach(notificationEntry => {
        const notificationData = notificationEntry.val()
        const uid = notificationData.uid
        promiseList.push(
            admin.database().ref("/users/" + uid + "/token").once("value")
                 .then(sendPush(notificationData))
        )
    })
    return Promise.all(promiseList)
}

const sendPush = notificationData => tokenSnapshot => {
    const token = tokenSnapshot.val()
    let promise = null
    const {todoId, timestamp, uid} = notificationData
    if (token) {
        promise = admin
            .messaging()
            .sendToDevice(
                token,
                {data: {todoId, timestamp: "" + timestamp, uid}},
                {timeToLive: tenMinutes, priority: "high"}
            )
            .then(mdRes => {
                const tokenUnregistered = mdRes.results.find(mdResult => {
                    return mdResult.error && mdResult.error.code === "messaging/registration-token-not-registered"
                })
                if (tokenUnregistered) {
                    return deleteToken(uid, token)
                        .then(res => ({error: {mdRes, deleteTokenRes: res}}))
                }
                return mdRes
            })
    } else {
        promise = Promise.resolve({
            error: "Cannot send notification: token not found: ",
            notificationData: notificationData
        })
    }
    // const newTimestamp = max(Date.now(), timestamp) + (15 * minute)
    // return Promise.all([
    //     promise, createNotificationRef(uid, todoId).set({
    //         todoId,
    //         timestamp: newTimestamp
    //         , uid
    //     })
    // ])
    return promise
}

function createNotificationRef(uid, todoId) {
    return admin.database().ref("/notifications/" + uid + "---" + todoId)
}


function deleteToken(uid, token) {
    return admin.database().ref("/users/" + token).set(null)
}
