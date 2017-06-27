module.exports = {
    staticFileGlobs: [
        "assets/**",
        "*.png",
        "*.ico",
        "manifest.json",
        "app/**",
        "*.bundle.js",
        "bower_components/pouchdb/dist/pouchdb.js"
    ],
    importScripts:["notification-sw.js"]

}
