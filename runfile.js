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

const firebaseDeployDev = `firebase deploy --except functions --project dev --public dev/build/unbundled --token ${FIREBASE_TOKEN}`
const firebaseDeployProd = `firebase deploy --except functions --project prod --public docs --token ${FIREBASE_TOKEN}`

const doesTravisTagMatchReleaseSemVer =
    _.test(/^v[0-9]+\.[0-9]+\.[0-9]+$/, TRAVIS_TAG)

function validateNotPullRequest() {
    if (TRAVIS_PULL_REQUEST !== "false") {
        throw new Error("wont build/deploy for pull request !== 'false'")
    }
}

function validateBranchOrTag() {
    if (doesTravisTagMatchReleaseSemVer || TRAVIS_BRANCH === "master") {
        return
    }
    throw new Error("Won't build/deploy for branches other than master or non-sem-ver tags.")
}

function travisValidate() {
    console.info("TRAVIS_BRANCH=", TRAVIS_BRANCH)
    console.info("TRAVIS_TAG=", TRAVIS_TAG)
    console.info("TRAVIS_PULL_REQUEST=", TRAVIS_PULL_REQUEST)
    validateNotPullRequest()
    validateBranchOrTag()
}
export const travis = {
    deploy: function () {
        travisValidate()

        if (doesTravisTagMatchReleaseSemVer) {
            run(`${firebaseDeployProd} -m "travis: ${TRAVIS_TAG}"`)

        } else {
            run(firebaseDeployDev
                + ` -m "travis: ${TRAVIS_COMMIT_MESSAGE} https://github.com/jigargosar/elm-simple-gtd/commit/${TRAVIS_COMMIT}"`)
        }
    },
    build(){
        travisValidate()

        if (doesTravisTagMatchReleaseSemVer) {
            build.prod()
        } else {
            build.dev()
        }
    }
}

export const deploy = {
    prod(){
        run(firebaseDeployProd)
    },
    dev(){
        run(firebaseDeployDev)
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
