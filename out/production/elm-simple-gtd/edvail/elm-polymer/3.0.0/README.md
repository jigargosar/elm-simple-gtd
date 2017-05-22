# edvail/elm-polymer
###To install module, change directory to the root of your project, and run this command:
```bash
elm package install edvail/elm-polymer
```
###Usage:
```elm
import Polymer.Paper as Paper
import Polymer.Attributes
    exposing
        ( icon
        , label
        , path
        , selected
        , stringProperty
        )
import Polymer.Events
    exposing
        ( onIronSelect
        , onSelectedChanged
        , onTap
        , onValueChanged
        )


main = Paper.iconButton [ icon "stars" ] []
```
## Reference elements in HTML
Don't forget to install elements (using bower for example), and reference them in your html file.
```html
<link rel="import" href="../bower_components/paper-tabs/paper-tab.html">
<link rel="import" href="../bower_components/paper-tabs/paper-tabs.html">
```
Or you can import them in lazy mode using Ports:
```elm
port polymerImportElement : String -> Cmd msg

port onPolymerImportFailed : (Decode.Value -> msg) -> Sub msg

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [ onPolymerImportFailed messageToMsg ]

messageToMsg : Decode.Value -> Msg
messageToMsg message =
    "I can't import requested element :("
        |> View404
        |> ChangePage
```
```js
Polymer({
  is: 'x-app',
  ready() {
    this.app = Elm.Main.embed(this.$.main)this.app.ports.polymerImportElement
      .subscribe(path => this._importElement(path))
  },
  _importElement(path) {
    const url = this.resolveUrl(path)
    // Load page import on demand. Show 404 page if fails
    return this.importHref(url, null, this.app.ports.onPolymerImportFailed.send, true)
  }
})
```

###And of course PR's are very welcome :)
