"use strict";


import PouchDB from "./local-pouch-db"

import R from "ramda"

import sound from "./sound"

import Peer from "peerjs"

const _ = R

async function boot() {

    var peer = new Peer({host: 'sgtd-peer-js.herokuapp.com', port: ''});
    peer.on("error", console.error)
    peer.on('open', function(id) {
        console.log('My peer ID is: ' + id);
    });
    peer.on('connection', function(conn) { console.log(conn) });


    const dbMap = {
        "todo-db": await PouchDB("todo-db"),
        "project-db": await PouchDB("project-db"),
        "context-db": await PouchDB("context-db")
    }

    const allTodos = await dbMap["todo-db"].find({selector: {"_id": {"$ne": null}}})
    const allProjects = await dbMap["project-db"].find({selector: {"_id": {"$ne": null}}})
    const contexts = await dbMap["context-db"].find({selector: {"_id": {"$ne": null}}})
    // console.log(allTodos)

    const Elm = require("elm/Main.elm")
    const app = Elm["Main"]
        .embed(document.getElementById("root"), {
            now: Date.now(),
            encodedTodoList: allTodos,
            encodedProjectList: allProjects,
            encodedContextList: contexts
        })


    // app.ports["pouchDBBulkDocks"].subscribe(async([dbName, docs]) => {
    //     const bulkResult = await dbMap[dbName].bulkDocs(docs)
    //     // const conflicts =
    //     //     _.filter(_.compose(_.propEq("name", "conflict"), _.head)
    //     //     )(_.zip(bulkResult, docs))
    //     // console.log(conflicts)
    //     //
    //     console.log("bulkResult:", dbName, bulkResult, docs)
    //     app.ports["onPouchDBBulkDocksResponse"].send([dbName, bulkResult, docs])
    // })

    app.ports["pouchDBUpsert"].subscribe(async ([dbName, id, doc]) => {
        // console.log("upserting", dbName, doc, id)
        const upsertResult = await dbMap[dbName].upsert(id, doc)
        if (_.F()) {
            console.log("upsertResult", upsertResult)
        }
    });

    app.ports["startSync"].subscribe((id)=>{
        const conn =  peer.connect(id)
        conn.on('open', function() {
            // Receive messages
            conn.on('data', function(data) {
                console.log('Received', data);
            });

            // Send messages
            conn.send('Hello!');
            conn.on("error", console.error)
        });
    })


    app.ports["focusPaperInput"].subscribe((selector) => {
        setTimeout(() => {
            requestAnimationFrame(() => {
                const toFocus = document.querySelector(selector)
                // console.log("toFocus", toFocus, document.activeElement)
                if (toFocus && document.activeElement !== toFocus) {
                    toFocus.focus()
                } else {
                    // console.log("not focusing")
                }
                if (toFocus) {
                    toFocus.$.input.focus()
                }
            })
        }, 0)
    })


    app.ports["startAlarm"].subscribe(() => {
        sound.start()
    })


    app.ports["stopAlarm"].subscribe(() => {
        sound.stop()
    })
}

boot().catch(console.error)

//noinspection JSUnresolvedVariable
if (!WEB_PACK_DEV_SERVER &&'serviceWorker' in navigator) {
    //noinspection JSUnresolvedVariable
    navigator.serviceWorker.register('/service-worker.js');
}
