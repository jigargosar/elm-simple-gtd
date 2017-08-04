"use strict";

import "./vendor"
import sound from "./sound"
import Fire from "./fire"
import DB from "./lib/pouchdb-wrapper"
import $ from "jquery"
import _ from "ramda"
import Notifications from "./notifications"
import cryptoRandomString from "crypto-random-string"
import autosize from "autosize"
import localforage from "localforage"


export default async function () {
    const dbMap = {
        "todo-db": await DB("todo-db"),
        "project-db": await DB("project-db"),
        "context-db": await DB("context-db")
    }

    const allDocsPMap = _.map(db => db.findAll())(dbMap)

    const allDocsMap = {
        todo: await allDocsPMap["todo-db"],
        project: await allDocsPMap["project-db"],
        context: await allDocsPMap["context-db"],
    }

    function setupApp(app) {
        _.mapObjIndexed((db, name) => db.onChange(
            (doc) => {
                // console.log(`app.ports["pouchDBChanges"]:`,name, ":", doc.name || doc.text)
                return app.ports["pouchDBChanges"].send([name, doc])
            }
        ))(dbMap)

        app.ports["pouchDBUpsert"].subscribe(async ([dbName, id, doc]) => {
            dbMap[dbName].upsert(id, doc).catch(console.error)
        });

    }


    return {list:_.values(dbMap), allDocsMap, setupApp}

}
