const ef = require('electronify-server')


ef({
    url: 'http://localhost:8020/app.html#!/lists/contexts',
    // command:"nodemon",
    noServer: true,
    debug: true,
    window: {height: 768, width: 1024},
    ready: function (app) {
        // application event listeners could be added here
    },
    preLoad: function (app, window) {
        // window event listeners could be added here
    },
    postLoad: function (app, window) {
        // url finished loading
    },
    showDevTools: true
})
