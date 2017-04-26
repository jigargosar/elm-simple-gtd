self.addEventListener('notificationclick', function (event) {
    // console.log("notification click", event)
    // event.notification.close();

    event.waitUntil(
        clients
            .matchAll({type: "window"})
            .then(function (clientList) {
                for (var i = 0; i < clientList.length; i++) {
                    const client = clientList[i]
                    postMessage(client, event)
                    if (client.focus) {
                        return client.focus();
                    }
                }
                if (clients.openWindow) {
                    return clients
                        .openWindow(url)
                        .then(function(client) {
                            setTimeout(function () {
                                postMessage(client, event)
                            },2000)
                        })
                }
            })
    );

}, false);

function postMessage(client, event) {
    client.postMessage({
        type: "notification-clicked",
        action: event.action,
        data: event.notification.data
    })
}
