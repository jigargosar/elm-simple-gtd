if (IS_DEVELOPMENT_ENV) {
    const runtime = require('serviceworker-webpack-plugin/lib/runtime')

    const swScriptPath = IS_DEVELOPMENT_ENV ? "/notification-sw.js" : '/service-worker.js'

    module.exports = runtime.register()
}else{
    module.exports = navigator.serviceWorker.register('/service-worker.js')
}


// const swScriptPath = IS_DEVELOPMENT_ENV ? "/notification-sw.js" : '/service-worker.js'
// // const swScriptPath = "/notification-sw.js"
// export default navigator.serviceWorker.register(swScriptPath)
