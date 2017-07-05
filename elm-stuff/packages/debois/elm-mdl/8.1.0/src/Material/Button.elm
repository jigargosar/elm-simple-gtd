module Material.Button
    exposing
        ( Model
        , defaultModel
        , Msg
        , update
        , view
        , flat
        , raised
        , fab
        , minifab
        , icon
        , plain
        , colored
        , primary
        , accent
        , ripple
        , disabled
        , Property
        , link
        , render
        , type_
        , react
        )

{-| From the [Material Design Lite documentation](http://www.getmdl.io/components/#buttons-section):

> The Material Design Lite (MDL) button component is an enhanced version of the
> standard HTML `<button>` element. A button consists of text and/or an image that
> clearly communicates what action will occur when the user clicks or touches it.
> The MDL button component provides various types of buttons, and allows you to
> add both display and click effects.
>
> Buttons are a ubiquitous feature of most user interfaces, regardless of a
> site's content or function. Their design and use is therefore an important
> factor in the overall user experience. See the button component's Material
> Design specifications page for details.
>
> The available button display types are flat (default), raised, fab, mini-fab,
> and icon; any of these types may be plain (light gray) or colored, and may be
> initially or programmatically disabled. The fab, mini-fab, and icon button
> types typically use a small image as their caption rather than text.

See also the
[Material Design Specification]([https://www.google.com/design/spec/components/buttons.html).

Refer to
[this site](https://debois.github.io/elm-mdl/#buttons)
for a live demo.

# Render
@docs render

# Options

@docs Property
@docs type_

## Appearance
@docs plain, colored, primary, accent
@docs ripple, disabled

## Type
Refer to the
[Material Design Specification](https://www.google.com/design/spec/components/buttons.html)
for details about what type of buttons are appropriate for which situations.
@docs flat, raised, fab, minifab, icon
@docs link

# Elm architecture
@docs Model, defaultModel, Msg, update, view

# Internal use
@docs react

-}

import Html exposing (..)
import Html.Attributes exposing (..)
import Material.Component as Component exposing (Indexed, Index)
import Material.Helpers as Helpers
import Material.Options as Options exposing (cs, when)
import Material.Options.Internal as Internal
import Material.Ripple as Ripple

-- MODEL


{-|
-}
type alias Model =
    Ripple.Model


{-|
-}
defaultModel : Model
defaultModel =
    Ripple.model



-- ACTION, UPDATE


{-|
-}
type alias Msg =
    Ripple.Msg


{-| Component update.
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update action =
    Ripple.update action



-- VIEW


type alias Config =
    { ripple : Bool
    , link : Bool
    }


defaultConfig : Config
defaultConfig =
    { ripple = False
    , link = False
    }


{-| Properties for Button options.
-}
type alias Property m =
    Options.Property Config m


{-| Turn the `Button` from `button`-element to an `a`-element.
This allows for a button that looks like a button but can also
perform link actions.

    Button.render Mdl [0] model.mdl
      [ Button.link
      , Options.attribute <|
          Html.Attributes.href "#some-url"
      ]
      [ text "Link Button" ]
-}
link : String -> Property m
link href =
  Options.many 
    [ Internal.option (\options -> { options | link = True })
    , Internal.attribute <| Html.Attributes.href href 
    ]


{-| Set button to ripple when clicked.
-}
ripple : Property m
ripple =
    (\options -> { options | ripple = True })
        |> Internal.option


{-| Set button to "disabled".
-}
disabled : Property m
disabled =
    Internal.attribute <| Html.Attributes.disabled True


{-| Plain, uncolored button (default).
-}
plain : Property m
plain =
    Options.nop


{-| Color button with primary or accent color depending on button type.
-}
colored : Property m
colored =
    cs "mdl-button--colored"


{-| Color button with primary color.
-}
primary : Property m
primary =
    cs "mdl-button--primary"


{-| Color button with accent color.
-}
accent : Property m
accent =
    cs "mdl-button--accent"


{-| Sets the type of the button e.g.

    Button.render ...
      [ Button.type' "submit"
      ]
      [ ... ]
-}
type_ : String -> Property m
type_ =
   Html.Attributes.type_ >> Internal.attribute



{- Ladies & Gentlemen: My nastiest hack ever.

   Buttons with ripples are implemented as
     <button> ... <span> ... </span></button>
   elements. The button must blur itself when the mouse goes up or leaves, and the
   (ripple) span must clear its animation state under the same events.
   Unfortunately, on firefox, mousedown, mouseleave etc. don't trigger on elements
   inside buttons, so we have to install all handlers on button. But the only way
   I know of to blur something is the `Helpers.blurOn` trick, which seemingly precludes
   also doing anything on the elm side. We work around this by manually triggering
   a 'touchcancel' event on the inner span.

   Obviously, once Elm gets proper support for controlling focus/blur, we can dispense
   with all this nonsense.
-}
blurAndForward : String -> Attribute m
blurAndForward event =
    Html.Attributes.attribute
        ("on" ++ event)
        -- NOTE: IE Does not properly support 'new Event()'. This is a temporary workaround
        "this.blur(); (function(self) { var e = document.createEvent('Event'); e.initEvent('touchcancel', true, true); self.lastChild.dispatchEvent(e); }(this));"


{-| Component view function.
-}
view : (Msg -> m) -> Model -> List (Property m) -> List (Html m) -> Html m
view lift model config html =
    let
        summary =
            Internal.collect defaultConfig config

        listeners =
            Options.many
                [ Ripple.down lift "mousedown"
                , Ripple.down lift "touchstart"
                , Ripple.up lift "touchcancel"
                , Ripple.up lift "mouseup"
                , Ripple.up lift "blur"
                , Ripple.up lift "mouseleave"
                ]
    in
        Internal.apply summary
            (if summary.config.link then Html.a else Html.button)
            [ cs "mdl-button"
            , cs "mdl-js-button"
            , cs "mdl-js-ripple-effect" |> when summary.config.ripple
            , listeners
            ]
            [ Helpers.blurOn "mouseup"
            , Helpers.blurOn "mouseleave"
            , Helpers.blurOn "touchend"
            ]
            (if summary.config.ripple then
                List.concat
                    [ html
                    , [ Html.map lift <|
                            Ripple.view_
                                [ class "mdl-button__ripple-container" ]
                                model
                      ]
                    ]
             else
                html
            )


{-| From the
[Material Design Specification](https://www.google.com/design/spec/components/buttons.html#buttons-flat-buttons):

> Flat buttons are printed on material. They do not lift, but fill with color on
> press.
>
> Use flat buttons in the following locations:
>
>  - On toolbars
>  - In dialogs, to unify the button action with the dialog content
>  - Inline, with padding, so the user can easily find them

Example use (uncolored flat button, assuming properly setup model):

    import Material.Button as Button

    flatButton : Model -> Html
    flatButton model =
      Button.render Mdl [0] model.mdl
        [ Button.flat ]
        [ text "Click me!" ]

-}
flat : Property m
flat =
    Options.nop


{-| From the
[Material Design Specification](https://www.google.com/design/spec/components/buttons.html#buttons-raised-buttons):

> Raised buttons add dimension to mostly flat layouts. They emphasize functions
> on busy or wide spaces.
>
> Raised buttons behave like a piece of material resting on another sheet –
> they lift and fill with color on press.

Example use (colored raised button, assuming properly setup model):

    import Material.Button as Button

    raisedButton : Model -> Html
    raisedButton model =
      Button.render Mdl [0] model.mdl
        [ Button.raised ]
        [ text "Click me!" ]

-}
raised : Property m
raised =
    cs "mdl-button--raised"


{-| Floating Msg Button. From the
[Material Design Specification](https://www.google.com/design/spec/components/buttons-floating-action-button.html):

> Floating action buttons are used for a promoted action. They are distinguished
> by a circled icon floating above the UI and have motion behaviors that include
> morphing, launching, and a transferring anchor point.
>
> Floating action buttons come in two sizes:
>
>  - Default size: For most use cases
>  - Mini size: Only used to create visual continuity with other screen elements

This constructor produces the default size, use `minifab` to get the mini-size.

Example use (colored with a '+' icon):

    import Material.Button as Button
    import Material.Icon as Icon

    fabButton : Model -> Html
    fabButton model =
      Button.render Mdl [0] model.mdl
        [ Button.fab ]
        [ Icon.i "add" ]
-}
fab : Property m
fab =
    cs "mdl-button--fab"


{-| Mini-sized variant of a Floating Msg Button; refer to `fab`.
-}
minifab : Property m
minifab =
    cs "mdl-button--mini-fab"


{-| The [Material Design Lite implementation](https://www.getmdl.io/components/index.html#buttons-section)
also offers an "icon button", which we
re-implement here. See also
[Material Design Specification](http://www.google.com/design/spec/components/buttons.html#buttons-toggle-buttons).
Example use (no color, displaying a '+' icon):

    import Material.Button as Button
    import Material.Icon as Icon

    iconButton : Html
    iconButton =
      Button.render Mdl [0] model.mdl
        [ Button.icon ]
        [ Icon.i "add" ]
-}
icon : Property m
icon =
    cs "mdl-button--icon"



-- COMPONENT


type alias Store s =
    { s | button : Indexed Model }


( get, set ) =
    Component.indexed .button (\x y -> { y | button = x }) Ripple.model


{-| Component react function (update variant). Internal use only.
-}
react :
    (Component.Msg Msg textfield menu layout toggles tooltip tabs dispatch -> m)
    -> Msg
    -> Index
    -> Store s
    -> ( Maybe (Store s), Cmd m )
react =
    Component.react get set Component.ButtonMsg (Component.generalise update)


{-| Component render.  Below is an example, assuming boilerplate setup as
indicated in `Material` and a user message `PollMsg`.

    Button.render Mdl [0] model.mdl
      [ Button.raised
      , Button.ripple
      , Options.onClick PollMsg
      ]
      [ text "Fetch new" ]
-}
render :
    (Component.Msg Msg textfield menu snackbar toggles tooltip tabs dispatch -> m)
    -> Index
    -> { a | button : Indexed Ripple.Model }
    -> List (Property m)
    -> List (Html m)
    -> Html m
render =
    Component.render get view Component.ButtonMsg
