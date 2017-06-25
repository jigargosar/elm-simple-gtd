"use strict";

import howler from "howler"

export default  (function () {
    const Howl = howler.Howl

    const sound = new Howl({
        src: ['/assets/sound/alarm-trimmed.ogg'],
        loop: true,
    });

    /*let id1 = null;

    const start = () => {
        stop()
        id1 = sound.play()
        sound.fade(1, 0, 3000, id1)
    }

    const stop = () => {
        if (id1) sound.stop()
    }*/

    function start() {
        sound.play()
        setTimeout(function () {
            sound.stop()
        },5000)
    }

    return {
        start,
        stop:()=>{}
    }
}())
