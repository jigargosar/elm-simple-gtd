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
const $ = require("jquery")
window.jQuery = $
require("materialize-css/dist/js/materialize.js")
require("materialize-css/js/forms.js")
require("./jquery.trap")
require("jquery-ui/ui/position")
