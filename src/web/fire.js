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


export const setup = (app, dbList) => {
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


    app.ports["fireDataWrite"].subscribe(([path, value]) => {
        // console.log(`firebaseApp.database().ref(path).set(value)`, {path, value})
        const ref = firebaseApp.database().ref(path);
        ref.set(value)
           .catch(console.error)
    })

    function startReplicationToFirebase(uid, db) {
        const lasSeqKey = `pouch-fire-sync.${db.name}.out.lastSeq`
        const lastSeqString = localStorage.getItem(lasSeqKey)
        const lastSeq = parseInt(lastSeqString, 10) || 0

        const changes = db.changes({
            include_docs: true,
            live: true,
            since: lastSeq
        })

        const onChange = change => {
            // console.log("sending pouchdb change to firebase: ", change)
            const fireDoc = _.compose(_.omit("_rev"), _.merge(change.doc))
                             ({"firebaseServerPersistedAt": firebase.database.ServerValue.TIMESTAMP})
            return firebaseApp
                .database().ref(`/users/${uid}/${db.name}/${change.id}`)
                .set(fireDoc)
                .then(() => {
                    localStorage.setItem(lasSeqKey, change.seq)
                    return change.seq
                })
        }

        const errorStream = Kefir.fromEvents(changes, "error")
        const changeStream = Kefir.fromEvents(changes, "change")

        Kefir.merge([changeStream, errorStream])
             // .log()
             .map(onChange)
             .flatMap(Kefir.fromPromise)
             .onValue(val => console.log("fireSyncSuccess: ", val))
             .onError(e => console.error("fireSyncError: ", e))
        return changes
    }

    function startReplicationFromFirebase(uid, dbName) {
        const lastPersistedAtKey = `pouch-fire-sync.${dbName}.in.lastPersistedAt`
        const onFirebaseChange = dbName => snap => {
            const doc = snap.val()

            // const equalsOmittingPersistedAt = _.equals(_.omit(["firebaseServerPersistedAt"],doc))
            // console.log("fire: ignoring local firebase change")

            app.ports["onFirebaseChange"].send([dbName, doc])

            localStorage.setItem(lastPersistedAtKey,
                Math.min(doc.firebaseServerPersistedAt, Date.now())
            )

        }

        const lastPersistedAtString = localStorage.getItem(lastPersistedAtKey)
        const lastPersistedAt = parseInt(lastPersistedAtString, 10) || 0

        const todoDbRef = firebaseApp
            .database()
            .ref(`/users/${uid}/${dbName}`)
            .orderByChild("firebaseServerPersistedAt")
            .startAt(lastPersistedAt + 1)

        todoDbRef.on("child_added", onFirebaseChange(dbName))
        todoDbRef.on("child_changed", onFirebaseChange(dbName))
    }


    app.ports["fireStartSync"].subscribe(async (uid) => {
        _.map(changes => changes.cancel())(changesEmitters)
        changesEmitters = _.map((db) => {
            startReplicationFromFirebase(uid, db.name)
            return startReplicationToFirebase(uid, db)
        })(dbList)
    })


    app.ports["fireDataPush"].subscribe(([path, value]) => {
        console.log(`firebaseApp.database().ref(path).push(value)`, {path, value})
        firebaseApp.database().ref(path).push(value)
    })

    app.ports["signOut"].subscribe(() => {
        let googleAuth = document.getElementById('firebase-auth');
        googleAuth
            .signOut()
            .catch(console.error)
    })
}

export default {
    setup
}
