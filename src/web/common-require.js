"use strict";
require("babel-polyfill")
require("./bower_components/webcomponentsjs/webcomponents-loader")

// style
require("materialize-css/bin/materialize.css")
require("./pcss/main.pcss")


// lib
require("ramda")
require('crypto-random-string')
require("kefir")


// jquery
const jQuery = require("jquery")
window.jQuery = global.jQuery = jQuery
// window.$ = global.$ = jQuery

require("materialize-css")
require("materialize-css/js/forms.js")
require("./jquery.trap")
require("jquery-ui/ui/position")
