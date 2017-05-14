"use strict"

const functions = require('firebase-functions')
const admin = require("firebase-admin")

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
exports.helloWorld = functions.https.onRequest((request, response) => {
    response.send("Hello from Firebase!");
});

const second = 1000
const minute = 60 * second

exports.testPush = functions.https.onRequest((request, response) => {
    // admin.database().ref('/messages').push({original: original}).then(snapshot => {
    //     // Redirect with 303 SEE OTHER to the URL of the pushed object in the Firebase console.
    //     res.redirect(303, snapshot.ref);
    // });
    return admin.messaging()
         .sendToDevice(
             "fs_Fhp9WAGc:APA91bH9WAT9nfgn1XJhrkZtxojLOlX3o6fdA6oJ0U2ZMPaOFrDzfzy7VVuwOpUeT2YGrHf2eN63arSVwkDpZeXywP5bpgYT-ntJfyf1bcwiErmF72Uh2Bi__nlO61L0oOXxSDEsLRWs",
             {data: {id: "7aIPoEclCGfR6lPUXb71hGXdoETwthsaETqSK98Bne2qyw2uWJcTgKDj03lpPCDt"}},
             {timeToLive: (10 * minute), priority:"high"}
         )
        .then(()=>response.send("push sent"))
});
