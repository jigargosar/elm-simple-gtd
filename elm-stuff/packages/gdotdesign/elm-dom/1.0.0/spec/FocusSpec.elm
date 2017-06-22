import Spec exposing (describe, it, Node, before)
import Spec.Assertions exposing (assert)
import Spec.Steps exposing (click)
import Spec.Runner

import Html.Events exposing (onFocus, onClick, onWithOptions)
import Html exposing (div, button, text, input, span)
import Html.Attributes exposing (class, tabindex)

import Json.Decode as Json

import Task
import DOM

type alias Model
  = ( String, String )


type Msg
  = Focused (Result DOM.Error ())
  | FocusSync String
  | Focus String
  | Blur String
  | CheckFocus
  | OnFocus


init : () -> Model
init _ = ( "", "" )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ( result, focusResult ) =
  case msg of
    Blur selector ->
      case DOM.blurSync selector of
        Ok () -> ( ( result, "BLURED" ), Cmd.none )
        Err error -> ( ( toString error, focusResult ), Cmd.none )

    CheckFocus ->
      if DOM.hasFocusedElementSync () then
        ( ( "HAS FOCUSED", focusResult ), Cmd.none )
      else
        ( ( "NO FOCUSED", focusResult ), Cmd.none )

    OnFocus ->
      ( ( result, "FOCUSED" ), Cmd.none )

    Focused result ->
      case result of
        Ok () -> ( ( "OK", focusResult ), Cmd.none )
        Err error -> ( ( toString error, focusResult ), Cmd.none )

    FocusSync selector ->
      case DOM.focusSync selector of
        Ok () -> ( ( "OK", focusResult ), Cmd.none )
        Err error -> ( ( toString error, focusResult ), Cmd.none )

    Focus selector ->
      ( ( result, focusResult ), Task.attempt Focused (DOM.focus selector) )


view : Model -> Html.Html Msg
view (result, focusResult) =
  div []
    [ input [ onFocus OnFocus ] []
    , span [ tabindex 0, onFocus OnFocus ] []
    , button [ class "focus", onClick (Focus "input") ] []
    , button [ class "focus-tabindex", onClick (Focus "span[tabindex]") ] []
    , button [ class "focus-invalid", onClick (Focus "---**.") ] []
    , button [ class "focus-not-found", onClick (Focus "asd") ] []
    , button [ class "check-focus", onClick CheckFocus ] []
    , button [ class "blur-input", onClick (Blur "input") ] []
    , button [ class "blur-span", onClick (Blur "span") ] []
    , div [ class "result" ] [ text result ]
    , div [ class "focus-result" ] [ text focusResult ]
    ]


specs : Node
specs =
  describe "Focus"
    [ before
      [ assert.containsText { text = "", selector = "div.result" }
      , assert.containsText { text = "", selector = "div.focus-result" }
      ]
    , describe ".hasFocusedElement"
      [ it "should return false if there is no element in focus"
        [ click "button.check-focus"
        , assert.containsText { text = "NO FOCUSED", selector = "div.result" }
        ]
      ]
    , describe ".focus"
      [ it "should focus valid elements"
        [ click "button.focus"
        , assert.containsText { text = "OK", selector = "div.result" }
        , assert.containsText { text = "FOCUSED", selector = "div.focus-result" }
        , click "button.check-focus"
        , assert.containsText { text = "HAS FOCUSED", selector = "div.result" }
        , click "button.blur-input"
        , assert.containsText { text = "BLURED", selector = "div.focus-result" }
        ]
      ,  it "should focus tabindexed elements"
        [ click "button.focus-tabindex"
        , assert.containsText { text = "OK", selector = "div.result" }
        , assert.containsText { text = "FOCUSED", selector = "div.focus-result" }
        , click "button.check-focus"
        , assert.containsText { text = "HAS FOCUSED", selector = "div.result" }
        ]
      , it "should return false for invalid selector"
        [ click "button.focus-invalid"
        , assert.containsText { text = "InvalidSelector", selector = "div.result" }
        , assert.containsText { text = "", selector = "div.focus-result" }
        ]
      , it "should return false for not found selector"
        [ click "button.focus-not-found"
        , assert.containsText { text = "ElementNotFound", selector = "div.result" }
        , assert.containsText { text = "", selector = "div.focus-result" }
        , click "button.blur-span"
        , assert.containsText { text = "BLURED", selector = "div.focus-result" }
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
