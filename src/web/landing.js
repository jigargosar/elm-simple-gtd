import "./entry"
window.landingBoot = async function appBoot() {
    const Elm = require("elm/L/Main.elm")
    console.log(Elm)
    const app =
        Elm["L"]["Main"]
            .embed(document.getElementById("elm-container"))
}

