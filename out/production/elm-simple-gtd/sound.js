"use strict";

import howler from "howler"

module.exports= (function () {
    const Howl = howler.Howl

    const sound = new Howl({
        src: ['alarm.ogg']
    });

    let id1 = null;

    const start = () => {
        stop()
        id1 = sound.play()
        sound.fade(1, 0, 2000, id1)
    }

    const stop = () => {
        if (id1) sound.stop()
    }

    return {
        start,
        stop
    }
}())
