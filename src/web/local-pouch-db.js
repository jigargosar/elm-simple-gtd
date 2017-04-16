"use strict";

import PouchDB from "pouchdb-browser"
const _ = require("ramda")
const replicationStream = require('pouchdb-replication-stream')
const MemoryStream = require('memorystream')

// PouchDB.debug.enable("*")
PouchDB.debug.disable()
PouchDB.plugin(require('pouchdb-find'))
PouchDB.plugin(require('pouchdb-upsert'))
PouchDB.plugin(replicationStream.plugin);
PouchDB.adapter('writableStream', replicationStream.adapters.writableStream);


global.PouchDB = PouchDB

export default async(dbName, indices = []) => {
    const db = new PouchDB(dbName)

    function createIndex(index) {
        return db.createIndex(index)
        // .then(console.log)
    }

    async function deleteIndices(){
        const existingCustomIndices = _.filter(_.prop("ddoc"), (await db.getIndexes()).indexes)
        return await Promise.all(_.map(_.bind(db.deleteIndex, db), existingCustomIndices))
    }

    // await deleteIndices();


    const bulkDocs = docs => db.bulkDocs(docs)
    const upsert = (id, doc) => db.upsert(id, _.always(doc))

    const remove = doc => db.put(_.merge(doc, {_deleted: true}))

    function startRemoteSync(remoteUrl = "http://localhost:12321", dbName_ = dbName) {
        console.log(`starting sync for ${dbName_}`)
        const remoteURL = `${remoteUrl}/${dbName_}`;
        const remoteCouch = new PouchDB(remoteUrl);
        db.sync(remoteURL,
            {live: true, retry: true},
            e => {
                console.error(`PLDB: sync err ${dbName_}`, e)
            });
    }

    const find = async options => (await db.find(options)).docs

    async function deleteAllDocs() {
        const docs = await db.allDocs()
        return await Promise.all(_.map(remove, docs))
    }

    await Promise.all(_.map(createIndex, indices))

    // //noinspection JSUnresolvedVariable
    // if (WEB_PACK_DEV_SERVER === true) {
    //     startRemoteSync()
    // }

    return {
        find,
        deleteAllDocs,
        bulkDocs,
        _db: db,
        upsert,
        deleteIndices,
        _allDocs: async () => await db.allDocs(),
        replicateToStream:function (stream) {
            return db.dump(stream)
        },
        startRemoteSync
    }
}


