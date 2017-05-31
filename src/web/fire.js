"use strict";
const _ = require("ramda")
const Kefir = require("kefir")


const firebaseDevConfig = {
    apiKey: "AIzaSyASFVPlWjIrpgSlmlEEIMZ0dtPFOuRC0Hc",
    authDomain: "rational-mote-664.firebaseapp.com",
    databaseURL: "https://rational-mote-664.firebaseio.com",
    projectId: "rational-mote-664",
    storageBucket: "rational-mote-664.appspot.com",
    messagingSenderId: "49437522774"
}

const firebaseProdConfig = {
    apiKey: "AIzaSyDgqOiOMuTvK3PdzJ0Oz6ctEg-devcgZYc",
    authDomain: "simple-gtd-prod.firebaseapp.com",
    databaseURL: "https://simple-gtd-prod.firebaseio.com",
    projectId: "simple-gtd-prod",
    storageBucket: "simple-gtd-prod.appspot.com",
    messagingSenderId: "1061254169900"
}

//noinspection JSUnresolvedVariable
const firebaseConfig =
    IS_DEVELOPMENT_ENV ? firebaseDevConfig : firebaseProdConfig


export const setup = (app, dbList, localDeviceId) => {
    const firebaseApp = firebase.initializeApp(firebaseConfig);
    let changesEmitters = []

    app.ports["signIn"].subscribe(() => {
        let provider = new firebase.auth.GoogleAuthProvider();
        provider.setCustomParameters({
            prompt: 'select_account',
            // prompt: 'consent'
        })

        document.getElementById('firebase-auth')
                .signInWithPopup(provider)
                .catch(console.error)
    })


    function isDocChangeLocal(doc) {
        const docDeviceId = doc.deviceId
        return !docDeviceId || docDeviceId === "" || docDeviceId === localDeviceId
    }

    function startReplicationToFirebase(uid, db) {
        const lastSeqKey = `pouch-fire-sync.${db.name}.out.lastSeq`
        const lastSeqString = localStorage.getItem(lastSeqKey)
        const lastSeq = parseInt(lastSeqString, 10) || 0

        const changes = db.changes({
            include_docs: true,
            live: true,
            since: lastSeq
        })


        const onChange = change => {
            const updateLastSeq = () => {
                localStorage.setItem(lastSeqKey, change.seq)
                return change.seq
            }
            if (isDocChangeLocal(change.doc)) {

                // console.log("sending pouchdb change to firebase: ", change)
                console.log("[PouchToFire]: sending local change: ",
                    change, change.doc.deviceId, localDeviceId)

                const fireDoc =
                    _.compose(_.omit("_rev"), _.merge(change.doc)
                    )({"firebaseServerPersistedAt": firebase.database.ServerValue.TIMESTAMP})


                return firebaseApp
                    .database().ref(`/users/${uid}/${db.name}/${change.id}`)
                    .set(fireDoc)
                    .then(updateLastSeq)
            }
            else{
                console.log("[PouchToFire]: ignoring non-local change: ",
                    change, change.doc.deviceId, localDeviceId)
                return Promise.resolve(updateLastSeq())
            }
        }

        const errorStream = Kefir.fromEvents(changes, "error")
        const changeStream = Kefir.fromEvents(changes, "change")

        Kefir.merge([changeStream, errorStream])
             // .log()
             .map(onChange)
             .flatMap(Kefir.fromPromise)
             .onValue(msg => console.log("[PouchToFire] ", msg))
             .onError(e => console.error("[PouchToFire] ", e))
        return changes
    }

    function startReplicationFromFirebase(uid, db) {
        const dbName = db.name
        const lastPersistedAtKey = `pouch-fire-sync.${dbName}.in.lastPersistedAt`

        function updateLastPersistedAt(doc) {
            localStorage.setItem(lastPersistedAtKey,
                Math.min(doc.firebaseServerPersistedAt, Date.now())
            )
        }

        const onFirebaseChange = doc => {
            app.ports["onFirebaseChange"].send([dbName, doc])
            updateLastPersistedAt(doc)
        }

        const lastPersistedAtString = localStorage.getItem(lastPersistedAtKey)
        const lastPersistedAt = parseInt(lastPersistedAtString, 10) || 0

        const todoDbRef = firebaseApp
            .database()
            .ref(`/users/${uid}/${dbName}`)
            .orderByChild("firebaseServerPersistedAt")
            .startAt(lastPersistedAt + 1)

        // todoDbRef.on("child_added", onFirebaseChange(dbName))
        // todoDbRef.on("child_changed", onFirebaseChange(dbName))

        const changeStream = Kefir.merge([
            Kefir.fromEvents(todoDbRef, "child_changed"),
            Kefir.fromEvents(todoDbRef, "child_added")
        ])
        changeStream
            .map(_.invoker(0, "val"))
            .map(doc =>
                db.getClean(doc._id)
                  .then(_.omit(["_rev"]))
                  // .then(_.equals(_.omit(["firebaseServerPersistedAt"], doc)))
                  .then(isDocChangeLocal(doc))
                  .then((isLocalChange) => {
                      if (isLocalChange) {
                          updateLastPersistedAt(doc)
                          return "[FireToELm] ignoring local change: note we receive this message twice when online, since we are setting firebaseServerPersistedAt field."
                      } else {
                          onFirebaseChange(doc)
                          return "[FireToELm] sending non-local change"
                      }
                  })
                  .catch(e => {
                      if (e.status === 404) {
                          onFirebaseChange(doc)
                          return "[FireToELm] docs not found locally, sending to elm"
                      }
                      throw e;
                  })
            )
            .flatMap(Kefir.fromPromise)
            .onValue(msg => console.log(msg))
            .onError(e => {
                console.error("[FireToELm] ", e)
            })
    }


    app.ports["fireStartSync"].subscribe(async (uid) => {
        _.map(changes => changes.cancel())(changesEmitters)
        changesEmitters = _.map((db) => {
            startReplicationFromFirebase(uid, db)
            return startReplicationToFirebase(uid, db)
        })(dbList)
    })

    app.ports["firebaseSetupOnDisconnect"].subscribe(([uid, deviceId]) => {
        console.log("[FJS]:firebaseSetupOnDisconnect: called")
        const connectedRef = firebaseApp.database().ref(`/users/${uid}/clients/${deviceId}/connected`)
        connectedRef.onDisconnect().set(false)
    })

    app.ports["firebaseRefSet"].subscribe(([path, value]) => {
        // console.log(`firebaseApp.database().ref(path).set(value)`, {path, value})
        const ref = firebaseApp.database().ref(path);
        ref.set(value)
           .catch(console.error)
    })

    app.ports["firebaseRefPush"].subscribe(([path, value]) => {
        console.log(`firebaseApp.database().ref(path).push(value)`, {path, value})
        firebaseApp.database().ref(path).push(value)
    })

    app.ports["signOut"].subscribe(() => {
        let googleAuth = document.getElementById('firebase-auth');
        googleAuth
            .signOut()
            .catch(console.error)
    })
    return {
        ref(...args){
            return firebaseApp.database().ref(...args)
        }
    }
}

export default {
    setup
}
