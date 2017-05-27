"use strict"
import {run} from 'runjs'
import * as _ from "ramda"
import json from "jsonfile"

const runF = (cmd, options = {}) => () => run(cmd, options)

const fetchPackageJson = () => json.readFileSync("package.json")
const fetchPackageVersion = () => fetchPackageJson().version

const getDocsCommitMsg = () =>
    `[runfile-commit-docs] ${fetchPackageVersion()}`

export const docs = {
    gitStatus(){
        run("git status docs")
    },
    commit(){
        run("git unstage .")
        run("git add docs/**")
        run(`git commit -m '${getDocsCommitMsg()}'`)
    }
}
const firebaseDevOpts = "--project dev --public dev/build/unbundled"
const firebaseProdOpts = "--project prod --public docs"
export const travis = {

    deploy: {
        dev: () => {
            console.log(commit, commitMsg)
            run(`firebase deploy ${firebaseDevOpts} --token $FIREBASE_TOKEN_DEV `
                + `-m "travis: "$TRAVIS_COMMIT_MESSAGE" https://github.com/jigargosar/elm-simple-gtd/commit/$TRAVIS_COMMIT"`)
        },
        prod: () => run(`firebase deploy ${firebaseProdOpts} --token $FIREBASE_TOKEN_PROD -m "travis: $TRAVIS_TAG"`)
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

        if (_.test(/^v[0-9]+\.[0-9]+\.[0-9]+$/, tagName)) {
            build.prod(true)
        } else {
            build.dev(true)
        }
    }
}

export const deploy = {
    prod(deployFunctions = false){
        if (deployFunctions) {
            run(`firebase deploy ${firebaseProdOpts}`)
        }
        else {
            run(`firebase deploy --except functions ${firebaseProdOpts}`)
        }
    },
    dev(deployFunctions = false){
        build.dev()
        if (deployFunctions) {
            run(`firebase deploy ${firebaseDevOpts}`)
        }
        else {
            run(`firebase deploy --except functions ${firebaseDevOpts}`)
        }
    },
}


const dev = () => {
    return {
        buildRunOptions: {
            env: {NODE_ENV: "development", npm_package_version: fetchPackageJson().version}
        }
    }
}
const prod = () => {
    return {
        buildRunOptions: {
            env: {NODE_ENV: "production", npm_package_version: fetchPackageJson().version}
        }
    }
}

export const hot = runF(`webpack-dev-server --hot --inline`, dev().buildRunOptions)

export const hotmon = () => {
    run(`nodemon --watch runfile.js --watch webpack.config.babel.js --watch package.json --exec "run hot"`,
        dev().buildRunOptions)
}

export const testBump = () => {
    run("npm_bump --auto --auto-fallback patch 2>&1 | awk 'BEGIN{s=0} /Error/{s=1} 1; END{exit(s)}'")
}

export const bump = function () {
    run("npm_bump --auto --auto-fallback patch --skip-push 2>&1 | awk 'BEGIN{s=0} /Error/{s=1} 1; END{exit(s)}'")
    build.prod()
    build.commitDocs()
    deploy.dev()
}

console.log(this)

export const build = {
    commitDocs: function () {
        docs.gitStatus()
        docs.commit()
        docs.gitStatus()
    },
    dev: function (travis = false) {
        run("rimraf dev")
        run("cp -R static/ dev")
        const travisPrefix = travis ? "sysconfcpus -n 2" : ""
        run(`${travisPrefix} webpack --progress`, dev().buildRunOptions)
        run("polymer --version", {cwd: "dev"})
        run(`${travisPrefix} polymer build`, {cwd: "dev"})
    },
    prod: function (travis = false) {
        run("rimraf app && rimraf docs && rimraf build")
        run("cp -R static/ app")
        const travisPrefix = travis ? "sysconfcpus -n 2" : ""
        run(`${travisPrefix} webpack -p --progress`, prod().buildRunOptions)
        run("polymer --version", {cwd: "app"})
        run(`${travisPrefix} polymer build`, {cwd: "app"})
        run("cp -R app/build/unbundled/ docs")
    }
}

export function dummy(...args) {
    console.log("running dummy", this.options, args)
    console.log("calling dummy 2, passing options")
    dummy2.apply(this, args)
}

export function dummy2(...args) {
    console.log("running dummy2", this.options, args)
}

dummy.help = 'logs all options and args to console'
