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

exports.testPush = functions.https.onRequest((req, res) => {
    // admin.database().ref('/messages').push({original: original}).then(snapshot => {
    //     // Redirect with 303 SEE OTHER to the URL of the pushed object in the Firebase console.
    //     res.redirect(303, snapshot.ref);
    // });
    return admin.database().ref("/users").once("value")
                .then(sendTestPushToAllUsersWithRegistrationToken)
                .then(arr => res.send(arr))

    /*return admin.messaging()
     .sendToDevice(
     "fs_Fhp9WAGc:APA91bH9WAT9nfgn1XJhrkZtxojLOlX3o6fdA6oJ0U2ZMPaOFrDzfzy7VVuwOpUeT2YGrHf2eN63arSVwkDpZeXywP5bpgYT-ntJfyf1bcwiErmF72Uh2Bi__nlO61L0oOXxSDEsLRWs",
     {data: {id: "7aIPoEclCGfR6lPUXb71hGXdoETwthsaETqSK98Bne2qyw2uWJcTgKDj03lpPCDt"}},
     {timeToLive: (10 * minute), priority: "high"}
     )
     .then(() => res.send("push sent"))*/
});

exports.monitorPushRequests =
    functions
        .database.ref('/users/{uid}/notifications/{todoId}')
        .onWrite(event => {
            const todo = event.data.val()
            if (!todo) return;
            const uid = event.params.uid
            const todoId = event.params.todoId
            const hasReminder = todo.reminder && todo.reminder.at
            const notificationRef = admin.database().ref("/notifications/" + uid + "---" + todoId)
            if (hasReminder) {
                return notificationRef.set({uid: uid, todo: todo, time: todo.reminder.at})
            } else {
                return Promise.all(event.data.ref.set(null), notificationRef.set(null))
            }
        })

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
                    {data: {id: "7aIPoEclCGfR6lPUXb71hGXdoETwthsaETqSK98Bne2qyw2uWJcTgKDj03lpPCDt"}},
                    {timeToLive: (10 * minute), priority: "high"}
                )
            promiseList.push(promise)
        }
    })
    return Promise.all(promiseList)
}


exports.notificationCorn = functions.https.onRequest((req, res) => {
    return admin
        .database().ref("/notifications")
        .orderByChild("time")
        .endAt(Date.now() + (10 * minute))
        .once("value")
        .then(sendPushNotifications)
        .then(arr => res.send(arr))

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
    if (token) {
        return admin
            .messaging()
            .sendToDevice(
                token,
                {data: notificationData.todo},
                {timeToLive: (10 * minute), priority: "high"}
            )
    } else {
        return Promise.resolve({
            error: "Cannot send notification: token not found: ",
            notificationData: notificationData
        })
    }
}
