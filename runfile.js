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

const FIREBASE_TOKEN = process.env["FIREBASE_TOKEN"]
const TRAVIS_TAG = process.env["TRAVIS_TAG"]
const TRAVIS_PULL_REQUEST = process.env["TRAVIS_PULL_REQUEST"]
const TRAVIS = process.env["TRAVIS"]
const TRAVIS_COMMIT = process.env["TRAVIS_COMMIT"]
const TRAVIS_COMMIT_MESSAGE = process.env["TRAVIS_COMMIT_MESSAGE"]
const TRAVIS_BRANCH = process.env["TRAVIS_BRANCH"]

const firebaseDevOpts = `--project dev --public dev/build/unbundled --token ${FIREBASE_TOKEN}`
const firebaseProdOpts = `--project prod --public docs --token ${FIREBASE_TOKEN}`

const doesTravisTagMatchReleaseSemVer =
    _.test(/^v[0-9]+\.[0-9]+\.[0-9]+$/, TRAVIS_TAG)

function validateNotPullRequest() {
    if (TRAVIS_PULL_REQUEST !== "false") {
        throw new Error("wont build for pull request !== 'false'")
    }
}
export const travis = {
    deploy: function () {
        validateNotPullRequest()

        if (doesTravisTagMatchReleaseSemVer) {
            run(`firebase deploy ${firebaseProdOpts}  -m "travis: $TRAVIS_TAG"`)

        } else if (TRAVIS_BRANCH === "master") {
            run(`echo "https://github.com/jigargosar/elm-simple-gtd/commit/$TRAVIS_COMMIT"`)
            run("echo $TRAVIS_COMMIT_MESSAGE")
            run(`firebase deploy ${firebaseDevOpts} `
                + `-m "travis: ${TRAVIS_COMMIT_MESSAGE} https://github.com/jigargosar/elm-simple-gtd/commit/${TRAVIS_COMMIT}"`)
        } else {
            throw new Error("Won't deploy for branches other than master or non-sem-ver tags.")
        }
    },
    build(){
        console.info("TRAVIS_BRANCH=", TRAVIS_BRANCH)
        console.info("TRAVIS_TAG=", TRAVIS_TAG)
        console.info("TRAVIS_PULL_REQUEST=", TRAVIS_PULL_REQUEST)
        validateNotPullRequest()

        if (doesTravisTagMatchReleaseSemVer) {
            build.prod()
        } else if (TRAVIS_BRANCH === "master") {
            build.dev()
        } else {
            throw new Error("Won't build for branches other than master or non-sem-ver tags.")
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
        // build.dev()
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

export const bump = function () {
    if (this.options && (this.options["c"] || this.options["commit-docs"])) {
        run("npm_bump --auto --auto-fallback patch --skip-push 2>&1 | awk 'BEGIN{s=0} /Error/{s=1} 1; END{exit(s)}'")
        build.prod()
        build.commitDocs()
        deploy.dev()
    } else {
        run("npm_bump --auto --auto-fallback patch 2>&1 | awk 'BEGIN{s=0} /Error/{s=1} 1; END{exit(s)}'")
    }
}

const travisRunPrefix = TRAVIS ? "sysconfcpus -n 2" : ""
export const build = {
    commitDocs: function () {
        docs.gitStatus()
        docs.commit()
        docs.gitStatus()
    },
    dev: function () {
        console.info("build:dev")
        run("rimraf dev")
        run("cp -R static/ dev")
        run(`${travisRunPrefix} webpack --progress`, dev().buildRunOptions)
        run("polymer --version", {cwd: "dev"})
        run(`${travisRunPrefix} polymer build`, {cwd: "dev"})
    },
    prod: function () {
        console.info("build:prod")
        run("rimraf app && rimraf docs && rimraf build")
        run("cp -R static/ app")
        run(`${travisRunPrefix} webpack --progress`, prod().buildRunOptions)
        run("polymer --version", {cwd: "app"})
        run(`${travisRunPrefix} polymer build`, {cwd: "app"})
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
