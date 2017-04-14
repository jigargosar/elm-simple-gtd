"use strict";


import PouchDB from "./local-pouch-db"

import R from "ramda"

import sound from "./sound"

import Peer from "peerjs"

const _ = R

async function boot() {

    const id = localStorage.getItem("my-peer-id")
    if(id){
        const peer = new Peer(id, {secure:true, host: 'sgtd-peer-js.herokuapp.com', port: ''});
        peer.on("error", e => {
            console.dir(e)
            if(e.type === "network"){
                setTimeout(()=>{
                    peer.reconnect()
                },5000)
            }else{
                localStorage.removeItem("my-peer-id")
            }
        })
        peer.on('open', function(id) {
            console.log('My peer ID is: ' + id);
            localStorage.setItem("my-peer-id", id)
        });
        peer.on('connection', function(conn) {
            conn.on('data', function(data) {
                console.log('Received', data);
                conn.send("pong");
            });

            conn.on("error", e =>{
                console.dir(e)
                console.error("sync error", e)
            })
            conn.on("close", () =>{
                console.error("in coming conn closed")
            })
        });
    }


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


    app.ports["pouchDBUpsert"].subscribe(async ([dbName, id, doc]) => {
        // console.log("upserting", dbName, doc, id)
        const upsertResult = await dbMap[dbName].upsert(id, doc)
        if (_.F()) {
            console.log("upsertResult", upsertResult)
        }
    });

    app.ports["startSync"].subscribe((peerId)=>{
        const conn =  peer.connect(peerId)
        conn.on('open', function() {
            conn.send('ping');
        });
        conn.on('data', function(data) {
            console.log('Received', data);
        });
        conn.on("error", e =>{
            console.dir(e)
            console.error("open error", e)
        })
        conn.on("close", e =>{
            console.dir(e)
            console.error("closed", e)
        })
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
