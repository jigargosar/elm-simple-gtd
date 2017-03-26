"use strict";

import R from "ramda"
const _ = R

import howler from "howler"




const Howl = howler.Howl

const sound = new Howl({
    src: ['alarm.ogg']
});

const id1 = sound.play();

sound.fade(0, 1, 5000, id1);

