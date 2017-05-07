"use strict";

const PouchDB = require("pouchdb-browser")
const _ = require("ramda")

// PouchDB.debug.enable("*")
PouchDB.debug.disable()
PouchDB.plugin(require('pouchdb-find'))
PouchDB.plugin(require('pouchdb-upsert'))


export default async (dbName, indices = []) => {
    const db = new PouchDB(dbName)
    let syncTracker = null;

    function createIndex(index) {
        return db.createIndex(index)
        // .then(console.log)
    }

    async function deleteIndices() {
        const existingCustomIndices = _.filter(_.prop("ddoc"), (await db.getIndexes()).indexes)
        return await Promise.all(_.map(_.bind(db.deleteIndex, db), existingCustomIndices))
    }

    function bulkDocs(docs) {
        return db.bulkDocs(docs)
    }

    function upsert(id, doc) {
        return db.upsert(id, _.always(doc))
    }

    function startRemoteSync(remoteUrl = "http://localhost:12321", prefix = "", dbName_ = dbName) {
        const dbNameWithPrefix = `${prefix}${dbName_}`
        console.log(`starting sync for ${dbNameWithPrefix}`)
        const remoteURL = `${remoteUrl}/${dbNameWithPrefix}`;
        if (syncTracker) {
            syncTracker.cancel()
        }
        const tracker = db
            .sync(remoteURL,
                {live: true, retry: true},
                (error, result) => {
                    if (error) {
                        console.error(`PLDB: sync err ${dbName_}`, error)
                    } else {
                        console.info("PLDB: sync complete = ", result)
                    }

                })
        syncTracker = tracker
        return tracker
    }

    const find = async options => (await db.find(options)).docs

    function allDocs() {
        db.allDocs()
    }

    async function deleteAllDocs() {
        function remove(doc) {
            return db.put(_.merge(doc, {_deleted: true}))
        }

        return Promise.all(_.map(remove, await allDocs()))
    }

    // await deleteIndices();
    await Promise.all(_.map(createIndex, indices))


    function onChange(callback) {
        return db.changes({
            // since: 'now',
            live: true,
            include_docs: true
        }).on('change', function (change) {
            // console.log("change", change)
            callback(change.doc)
        }).on('complete', function (info) {
            // changes() was canceled
        }).on('error', function (err) {
            console.log(err);
        });
    }



    return {
        find,
        deleteAllDocs,
        bulkDocs,
        _db: db,
        upsert,
        deleteIndices,
        allDocs,
        startRemoteSync,
        findAll: () => find({selector: {"_id": {"$ne": null}}}),
        onChange
    }
}

