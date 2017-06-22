import Spec exposing (describe, it, Node, before)
import Spec.Assertions exposing (assert)
import Spec.Steps exposing (click)
import Spec.Runner

import Html exposing (div, button, text, span)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)

import DOM

type alias Model
  = String


type Msg
  = Contains String


init : () -> Model
init _ = ""


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    Contains selector ->
      if DOM.contains selector then
        ( "YES" , Cmd.none )
      else
        ( "NO", Cmd.none )


view : Model -> Html.Html Msg
view model =
  div []
    [ button [ class "contains", onClick (Contains "span") ] []
    , button [ class "contains-invalid", onClick (Contains "---**.") ] []
    , button [ class "contains-not-found", onClick (Contains "asd") ] []
    , div [ class "result" ] [ text model ]
    , span [] []
    ]


specs : Node
specs =
  describe "Contains"
    [ before
      [ assert.containsText { text = "", selector = "div.result" }
      ]
    , describe ".contains"
      [ it "should return true for valid"
        [ click "button.contains"
        , assert.containsText { text = "YES", selector = "div.result" }
        ]
      , it "should return false for invalid selector"
        [ click "button.contains-invalid"
        , assert.containsText { text = "NO", selector = "div.result" }
        ]
      , it "should return false for not found selector"
        [ click "button.contains-not-found"
        , assert.containsText { text = "NO", selector = "div.result" }
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
