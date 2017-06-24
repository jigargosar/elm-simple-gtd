module.exports = {
    staticFileGlobs: [
        "assets/**",
        "manifest.json",
        "app/index.html",
        "*.ogg",
        "*.png",
        "*.ico",
        "common.js",
        "vendor.js",
        "app.js",
        "landing.js",
        "*.woff",
        "*.woff2",
        "bower_components/pouchdb/dist/pouchdb.js"
    ],
    importScripts:["notification-sw.js"]

}
