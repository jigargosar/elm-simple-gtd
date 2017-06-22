import Spec exposing (describe, it, Node, before)
import Spec.Steps exposing (click, setValue)
import Spec.Assertions exposing (assert)
import Spec.Runner

import Html exposing (input, div, button, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)

import Task
import DOM


type alias Model
  = String


type Msg
  = DoneGetValue (Result DOM.Error String)
  | DoneSetValue (Result DOM.Error ())
  | GetValueSync String
  | GetValue String
  | SetValueSync String String
  | SetValue String String


init : () -> Model
init _ = ""


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    SetValueSync value selector ->
      case DOM.setValueSync value selector of
        Ok () -> ( "", Cmd.none )
        Err error -> ( toString error, Cmd.none )

    DoneSetValue result ->
      case result of
        Ok () -> ( "", Cmd.none )
        Err error -> ( toString error, Cmd.none )

    DoneGetValue result ->
      case result of
        Ok value -> ( value, Cmd.none )
        Err error -> ( toString error, Cmd.none )

    GetValueSync selector ->
      case DOM.getValueSync selector of
        Ok value -> ( value, Cmd.none )
        Err error -> ( toString error, Cmd.none )

    GetValue selector ->
      ( "", Task.attempt DoneGetValue (DOM.getValue selector))

    SetValue value selector ->
      ( "", Task.attempt DoneSetValue (DOM.setValue value selector) )


view : Model -> Html.Html Msg
view model =
  div []
    [ input [] [ ]
    , button [ class "set-value", onClick (SetValue "async" "input") ] []
    , button [ class "set-value-sync", onClick (SetValueSync "sync" "input") ] []
    , button [ class "set-value-error", onClick (SetValueSync "sync" "---**.") ] []
    , button [ class "set-value-not-found", onClick (SetValueSync "sync" "asd") ] []
    , button [ class "get-value", onClick (GetValue "input") ] []
    , button [ class "get-value-sync", onClick (GetValueSync "input") ] []
    , button [ class "get-value-error", onClick (GetValueSync "---**.**") ] []
    , button [ class "get-value-not-found", onClick (GetValueSync "asd") ] []
    , div [ class "result" ] [ text model ]
    ]


specs : Node
specs =
  describe "Value"
    [ before
      [ assert.valueEquals { text = "", selector = "input" }
      , assert.containsText { text = "", selector = "div.result" }
      ]
    , describe ".setValue"
      [ it "should set value asynchronously"
        [ click "button.set-value"
        , assert.valueEquals { text = "async", selector = "input" }
        ]
      , it "should set value synchronously"
        [ click "button.set-value-sync"
        , assert.valueEquals { text = "sync", selector = "input" }
        ]
      , it "should return error for invalid selector"
        [ click "button.set-value-error"
        , assert.containsText { text = "InvalidSelector", selector = "div.result" }
        ]
      , it "should return error for not found selector"
        [ click "button.set-value-not-found"
        , assert.containsText { text = "ElementNotFound", selector = "div.result" }
        ]
      ]
    , describe ".getValue"
      [ it "it should get value asynchronously"
        [ setValue { selector = "input", value = "test" }
        , click "button.get-value"
        , assert.containsText { text = "test", selector = "div.result" }
        ]
      , it "it should get value synchronously"
        [ setValue { selector = "input", value = "testSync" }
        , click "button.get-value-sync"
        , assert.containsText { text = "testSync", selector = "div.result" }
        ]
      , it "should return error for invalid selector"
        [ click "button.get-value-error"
        , assert.containsText { text = "InvalidSelector", selector = "div.result" }
        ]
      , it "should return error for not found selector"
        [ click "button.get-value-not-found"
        , assert.containsText { text = "ElementNotFound", selector = "div.result" }
        ]
      ]
    ]


main =
  Spec.Runner.runWithProgram
    { subscriptions = \_ -> Sub.none
    , update = update
    , view = view
    , init = init
    } specs
