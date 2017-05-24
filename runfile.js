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
        dev: runF("firebase deploy --project dev --public dev/build/unbundled --token $FIREBASE_TOKEN_DEV"),
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

export const deploy = {
    prod(deployFunctions = false){
        if (deployFunctions) {
            run("firebase deploy --project prod --public docs")
        }
        else {
            run("firebase deploy --except functions --project prod --public docs")
        }
    },
    dev(deployFunctions = false){
        if (deployFunctions) {
            run("firebase deploy --project dev --public dev/build/unbundled")
        }
        else {
            run("firebase deploy --except functions --project dev --public dev/build/unbundled")
        }
    },
}

export const build = {
    commitDocs(){
        docs.gitStatus()
        docs.commit()
        docs.gitStatus()
    },
    dev(){
        run("rimraf dev")
        run("cp -R static/ dev")
        run("cross-env NODE_ENV=development webpack --progress")
        run("cd dev")
        run("polymer --version")
        run("polymer build")
        run("cd .. ")
    },
    prod(){
        run("cp -R static/ app")
        run("cross-env NODE_ENV=production webpack --progress")
        run("cd app")
        run("polymer --version")
        run("polymer build")
        run("cd ..")
        run("cp -R app/build/unbundled/ docs")
    }
}

export function createcomponent(name) {

}

export function lint(path = '.') {
    this.options.fix ? run(`eslint ${path} --fix`) : run(`eslint ${path}`)
}

lint.help = 'Do linting for javascript files'
