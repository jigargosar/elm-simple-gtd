module.exports = IS_DEVELOPMENT_ENV ?
    require('serviceworker-webpack-plugin/lib/runtime').register()
    : navigator.serviceWorker.register('/service-worker.js');


// const swScriptPath = IS_DEVELOPMENT_ENV ? "/notification-sw.js" : '/service-worker.js'
// // const swScriptPath = "/notification-sw.js"
// export default navigator.serviceWorker.register(swScriptPath)
