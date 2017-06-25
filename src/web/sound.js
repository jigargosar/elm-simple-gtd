"use strict";

import howler from "howler"

export default  (function () {
    const Howl = howler.Howl

    const sound = new Howl({
        src: ['/assets/sound/alarm-trimmed.ogg'],
        loop: true,
    });

    function start() {
        const id1 = sound.play()

        setTimeout(function () {
            sound.fade(1, 0, 2000, id1)
        },1000)
        
        setTimeout(function () {
            sound.stop(id1)
        },5000)
    }

    return {
        start,
        stop:()=>{}
    }
}())
