import "./sw-register"
window.landingBoot = async function appBoot() {
    const Elm = require("elm/L/Main.elm")
    const app =
        Elm["L"]["Main"]
            .embed(document.getElementById("elm-container"))
}

