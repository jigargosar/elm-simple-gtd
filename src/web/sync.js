"use strict";
import Peer from "peerjs"

export default function (app) {

    const id = localStorage.getItem("my-peer-id")

    const peer = new Peer(id, {secure: true, host: 'sgtd-peer-js.herokuapp.com', port: ''});
    peer.on("error", e => {
        console.dir(e)
        if (e.type === "network") {
            setTimeout(() => {
                peer.reconnect()
            }, 5000)
        } else {
            localStorage.removeItem("my-peer-id")
        }
    })
    peer.on('open', function (id) {
        console.log('My peer ID is: ' + id);
        localStorage.setItem("my-peer-id", id)
        app.ports["peerIdChanged"].send(id)
    });
    peer.on('connection', function (conn) {
        conn.on('data', function (data) {
            console.log('Received', data);
            conn.send("pong");
        });

        conn.on("error", e => {
            console.dir(e)
            console.error("sync error", e)
        })
        conn.on("close", () => {
            console.error("in coming conn closed")
        })
    });

    return {
        peer
    }
}

