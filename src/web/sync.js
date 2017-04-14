"use strict";
import Peer from "peerjs"

export default function (app) {
    let peer = createPeer()
    let conn=null

    function createPeer() {
        const myPeerId = localStorage.getItem("my-peer-id")

        if (peer && peer.id !== myPeerId) {
            peer.destroy();
            return createPeer2(myPeerId)
        }
        if (!peer) {
            return createPeer2(myPeerId)
        }
        return peer;

    }


    function createPeer2(myPeerId) {
        const peer = new Peer(myPeerId, {secure: true, host: 'sgtd-peer-js.herokuapp.com', port: ''});
        peer.on("error", e => {
            console.dir(e)
            if (e.type === "network" && !peer.destroyed) {
                setTimeout(() => {
                    peer.reconnect()
                }, 5000)
            }
        })
        peer.on('open', function (id) {
            console.log('My peer ID is: ' + id);
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
                // console.error("in coming conn closed")
            })
        });
        
        return peer;
    }

    app.ports["startSync"].subscribe(([myPeerId, remotePeerId]) => {

        localStorage.setItem("my-peer-id", myPeerId)
        localStorage.setItem("remote-peer-id", remotePeerId)
        const oldPeer = peer

        peer = createPeer()

        if(oldPeer !== peer)
        {
            debugger
        }
        if(conn && !conn.closed) conn.close()
        conn = peer.connect(remotePeerId)
        conn.on('open', function () {
            conn.send('ping');
        });
        conn.on('data', function (data) {
            console.log('Received', data);
        });
        conn.on("error", e => {
            console.dir(e)
            console.error("open error", e)
        })

        conn.on("close", () => {
            //console.error("out bound conn closed")
        })

    })


}

