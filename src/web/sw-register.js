'use strict';

const reg = process.env.WEBPACK_DEV_SERVER === "true" ?
    require('serviceworker-webpack-plugin/lib/runtime').register()
    : register()

module.exports = reg;

function register() {
    if (!('serviceWorker' in navigator)) {
        return Promise.reject("ServiceWorker not supported")
    }
    return navigator.serviceWorker.register('service-worker.js')
}


reg.then(function (reg) {
    reg.update()
      .then(res => console.warn("sw-update result: ", res))
      .catch(console.error)

    // updatefound is fired if service-worker.js changes.
    reg.onupdatefound = function () {
        // The updatefound event implies that reg.installing is set; see
        // https://slightlyoff.github.io/ServiceWorker/spec/service_worker/index.html#service-worker-container-updatefound-event
        const installingWorker = reg.installing

        installingWorker.onstatechange = function () {
            switch (installingWorker.state) {
                case 'installed':
                    if (navigator.serviceWorker.controller) {
                        // At this point, the old content will have been purged and the fresh content will
                        // have been added to the cache.
                        // It's the perfect time to display a "New content is available; please refresh."
                        // message in the page's interface.
                        console.log('New or updated content is available.');
                    } else {
                        // At this point, everything has been precached.
                        // It's the perfect time to display a "Content is cached for offline use." message.
                        console.log('Content is now available offline!');
                    }
                    break;

                case 'redundant':
                    console.error('The installing service worker became redundant.');
                    break;
            }
        };
    };
    return reg
})


// const swScriptPath = IS_DEVELOPMENT_ENV ? "/notification-sw.js" : '/service-worker.js'
// // const swScriptPath = "/notification-sw.js"
// export default navigator.serviceWorker.register(swScriptPath)
