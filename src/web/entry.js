"use strict";

require("babel-polyfill")
require("./bower_components/webcomponentsjs/webcomponents-loader")

// style
// require("materialize-css/bin/materialize.css")
require("materialize-css/dist/js/materialize.min")
require("./scss/main.scss")
require("./pcss/main.pcss")


export const withDevTools = (
    // process.env.NODE_ENV === 'development' &&
    typeof window !== 'undefined' && window.devToolsExtension
);
