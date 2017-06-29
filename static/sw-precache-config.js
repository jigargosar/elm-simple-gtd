module.exports = {
    staticFileGlobs: [
        "assets/**",
        "*.png",
        "*.ico",
        "manifest.json",
        "app.html",
        "*.bundle.js",
        "bower_components/pouchdb/dist/pouchdb.js"
    ],
    importScripts:["notification-sw.js"]

}
