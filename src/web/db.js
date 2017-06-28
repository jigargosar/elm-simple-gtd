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
        encodedTodoList: await allDocsPMap["todo-db"],
        encodedProjectList: await allDocsPMap["project-db"],
        encodedContextList: await allDocsPMap["context-db"],
    }


    return dbMap

}
