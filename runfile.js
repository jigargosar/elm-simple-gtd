"use strict"
import {run} from 'runjs'
import * as _ from "ramda"

const runF = (cmd, options={}) => () => run(cmd, options)

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
            build.prod()
        } else {
            build.dev()
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
        build.dev()
        if (deployFunctions) {
            run("firebase deploy --project dev --public dev/build/unbundled")
        }
        else {
            run("firebase deploy --except functions --project dev --public dev/build/unbundled")
        }
    },
}

import json from "jsonfile"

const packageJson = json.readFileSync("package.json")

const dev = {
    buildRunOptions: {env: {NODE_ENV: "development", npm_package_version: packageJson.version}}
}
const prod = {
    buildRunOptions: {env: {NODE_ENV: "production", npm_package_version: packageJson.version}}
}

export const hot = runF(`webpack-dev-server --hot --inline`, dev.buildRunOptions)

export const hotmon = () => {
    run(`nodemon --watch runfile.js --watch webpack.config.babel.js --watch package.json --exec "run hot"`)
}


export const bump = () => {
    run("npm_bump --auto --auto-fallback patch --skip-push 2>&1 | awk 'BEGIN{s=0} /Error/{s=1} 1; END{exit(s)}'")
    build.prod()
    build.commitDocs()
    deploy.dev()
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
        run("webpack --progress", dev.buildRunOptions)
        run("polymer --version", {cwd: "dev"})
        run("polymer build", {cwd: "dev"})
    },
    prod(){
        run("rimraf app && rimraf docs && rimraf build")
        run("cp -R static/ app")
        run("webpack --progress", prod.buildRunOptions)
        run("polymer --version", {cwd: "app"})
        run("polymer build", {cwd: "app"})
        run("cp -R app/build/unbundled/ docs")
    }
}

export function createcomponent(name) {

}

export function lint(path = '.') {
    this.options.fix ? run(`eslint ${path} --fix`) : run(`eslint ${path}`)
}

lint.help = 'Do linting for javascript files'
