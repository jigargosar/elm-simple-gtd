import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html exposing (..)

import Json.Decode as Json

import Mouse
import Task

import DOM.Window
import DOM

type alias Model =
  { overButton : Bool
  , error : DOM.Error
  , rect : DOM.Dimensions
  }

type Msg
  = GetDimensions
  | GetDimensionsSync
  | GotDimensions (Result DOM.Error DOM.Dimensions)
  | GetDimensionsSyncFail
  | GetDimensionsFail
  | Focus
  | Focused (Result DOM.Error ())
  | FocusSync
  | Select
  | SelectDone (Result DOM.Error ())
  | SelectSync
  | Move Mouse.Position
  | ScrollToXSync
  | ScrollToYSync
  | ScrollIntoViewSync
  | Scrolled
  | SetValue
  | Input

init =
  { overButton = False
  , error = DOM.ElementNotFound ""
  , rect = { top = 0, left = 0, right = 0, bottom = 0, width = 0, height = 0 }
  }

update msg model =
  case msg of
    GetDimensionsSyncFail ->
      case DOM.getDimensionsSync "asd" of
        Ok rect -> ({ model | rect = rect }, Cmd.none)
        Err error -> ({ model | error = error }, Cmd.none)

    GetDimensionsSync ->
      case DOM.getDimensionsSync "button" of
        Ok rect -> ({ model | rect = rect }, Cmd.none)
        Err error -> ({ model | error = error }, Cmd.none)

    GotDimensions result ->
      case result of
        Ok rect -> ({ model | rect = rect }, Cmd.none)
        Err error -> ({ model | error = error }, Cmd.none)

    GetDimensions ->
      ( model, Task.attempt GotDimensions (DOM.getDimensions "button") )

    GetDimensionsFail ->
      ( model, Task.attempt GotDimensions (DOM.getDimensions "1-asd") )

    FocusSync ->
      case DOM.focusSync "#input1" of
        _ -> ( model, Cmd.none )

    Focus ->
      ( model, Task.attempt Focused (DOM.focus "#input2") )

    Focused result ->
      case result of
        Ok _ -> (model, Cmd.none)
        Err error -> ({ model | error = error }, Cmd.none)

    SelectDone result ->
      case result of
        Ok _ -> (model, Cmd.none)
        Err error -> ({ model | error = error }, Cmd.none)

    Select ->
      ( model, Task.attempt SelectDone (DOM.select "#input2"))

    SelectSync ->
      case DOM.selectSync "#input1" of
        _ -> ( model, Cmd.none )

    ScrollToXSync ->
      case DOM.setScrollLeftSync 50 "#scrollContainer" of
        Ok _ -> (model, Cmd.none)
        Err error -> ({ model | error = error }, Cmd.none)

    ScrollToYSync ->
      case DOM.setScrollTopSync 50 "#scrollContainer" of
        Ok _ -> (model, Cmd.none)
        Err error -> ({ model | error = error }, Cmd.none)

    ScrollIntoViewSync ->
      case DOM.scrollIntoViewSync "#viewElement" of
        Ok _ -> (model, Cmd.none)
        Err error -> ({ model | error = error }, Cmd.none)

    Scrolled ->
      let
        _ = Debug.log "Scroll left" (DOM.getScrollLeftSync "#scrollContainer")
        _ = Debug.log "Scroll top" (DOM.getScrollTopSync "#scrollContainer")
      in
        ( model, Cmd.none )

    SetValue ->
      case DOM.setValueSync "test value" "#input1" of
        Ok _ -> (model, Cmd.none)
        Err error -> ({ model | error = error }, Cmd.none)

    Input ->
      case DOM.getValueSync "#input1" of
        Ok value ->
          let
            _ = Debug.log "Value" value
          in
            (model, Cmd.none)
        Err error -> ({ model | error = error }, Cmd.none)

    Move position ->
      case DOM.isOver "button" { top = toFloat position.y, left = toFloat position.x } of
        Ok isOver -> ({ model | overButton = isOver }, Cmd.none)
        Err error -> ({ model | error = error }, Cmd.none)


view model =
  div []
    [ text (toString model)
    , div []
      [ button [ onClick GetDimensionsSync ] [ text "Get Dimensions Sync" ]
      , button [ onClick GetDimensions ] [ text "Get Dimensions" ]
      ]
    , div []
      [ button [ onClick GetDimensionsSyncFail ] [ text "Get Dimensions Sync Fail" ]
      , button [ onClick GetDimensionsFail ] [ text "Get Dimensions Fail" ]
      ]

    , input
      [ id "input1"
      , on "input" (Json.succeed Input)
      ] []
    , input [ id "input2" ] []

    , div []
      [ button [ onClick FocusSync ] [ text "Focus Sync" ]
      , button [ onClick Focus ] [ text "Focus" ]
      ]

    , div []
      [ button [ onClick SelectSync ] [ text "Select All Sync" ]
      , button [ onClick Select ] [ text "Select All" ]
      ]

    , div []
      [ button [ onClick SetValue ] [ text "Set Value" ]
      ]

    , div
      [ style
        [("width", "300px")
        ,("height", "300px")
        ,("overflow", "scroll")
        ]
      , on "scroll" (Json.succeed Scrolled)
      , id "scrollContainer"
      ]
      [ div
        [ style
          [("width", "500px")
          ,("height", "500px")
          ,("position", "relative")
          ]
        ]
        [ div
          [ style
            [("width", "50px")
            ,("height", "50px")
            ,("background", "red")
            ,("position", "absolute")
            ,("bottom", "0")
            ,("right", "0")
            ]
          , id "viewElement"
          ] []
        ]
      ]

    , div []
      [ button [ onClick ScrollToXSync ] [ text "ScrollToX Sync" ]
      , button [ onClick ScrollToYSync ] [ text "ScrollToY Sync" ]
      , button [ onClick ScrollIntoViewSync ] [ text "ScrollIntoViewSync Sync" ]
      ]
    ]

main =
  let
    _ = Debug.log "window width" (DOM.Window.width ())
    _ = Debug.log "window height" (DOM.Window.height ())
    _ = Debug.log "window scrollTop" (DOM.Window.scrollTop ())
    _ = Debug.log "window scrollLeft" (DOM.Window.scrollLeft ())
    _ = Debug.log "has body" (DOM.contains "body")
    _ = Debug.log "has something" (DOM.contains "something")
    _ = Debug.log "has invalid" (DOM.contains "1-something")
  in
    Html.program
      { init = (init, Cmd.none)
      , view = view
      , update = update
      , subscriptions = \_ -> Mouse.moves Move
      }
