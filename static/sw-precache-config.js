module.exports = {
    staticFileGlobs: [
        "assets/**",
        "*.ogg",
        "*.png",
        "*.ico",
        "*.woff",
        "*.woff2",
        "manifest.json",
        "app/index.html",
        "common.js",
        "vendor.js",
        "app.js",
        "landing.js",
        "bower_components/pouchdb/dist/pouchdb.js"
    ],
    importScripts:["notification-sw.js"]

}
