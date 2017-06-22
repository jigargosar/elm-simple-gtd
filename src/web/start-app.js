import app from "./app"
window.addEventListener('WebComponentsReady', () => {
    app().catch(console.error)
});

