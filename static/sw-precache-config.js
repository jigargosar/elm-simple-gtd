module.exports = {
    staticFileGlobs: [
        "assets/**",
        "*.png",
        "*.ico",
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
