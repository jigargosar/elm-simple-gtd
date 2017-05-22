"use strict"
import {run} from 'runjs'
import * as _ from "ramda"

const runF = cmd => () => run(cmd)

export const docs = {
    gitStatus(){
        run("git status docs")
    },
    commit(){
        run("git unstage .")
        run("git add docs/**")
        run("git commit -m '[npm-auto-commit] deploy docs'")
    }
}

export const travis = {
    deploy: {
        dev: runF("firebase deploy --project dev --public dev --token $FIREBASE_TOKEN_DEV"),
        prod: runF("firebase deploy --project prod --public docs --token $FIREBASE_TOKEN_PROD")
    },
    build(tagName, pullRequest){
        if (arguments.length !== 2) {
            throw new Error(
                `cannot build without tagName and pullRequest arguments
                tagName = ${tagName} pullRequest = ${pullRequest}
                `)
        }

        if (pullRequest !== "false") {
            throw new Error("wont build for pull request !== 'false'")
        }

        if (_.test(/^v[0-9]+\.[0-9]+\.[0-9]+$/, tagName) && pullRequest !== "false") {
            run("npm run build")
        } else {
            run("npm run build-dev")
        }
    }
}

export const build = {
    commitDocs(){
        docs.gitStatus()
        docs.commit()
        docs.gitStatus()
    }
}

export function createcomponent(name) {

}

export function lint(path = '.') {
    this.options.fix ? run(`eslint ${path} --fix`) : run(`eslint ${path}`)
}

lint.help = 'Do linting for javascript files'
