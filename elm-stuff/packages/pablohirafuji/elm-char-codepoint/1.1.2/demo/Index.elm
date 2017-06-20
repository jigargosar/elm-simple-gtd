module Index exposing (main)

import Html exposing (Html, div, text, button, ul, li, input)
import Html.Attributes exposing (type_)
import Html.Events exposing (onClick, onInput)
import Char
import Char.CodePoint as CodePoint


type alias Model =
    { char : Char
    }


model : Model
model =
    { char = '𝔸'
    }


type Msg
    = SetChar Char


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetChar char ->
            ( { model | char = char }
            , Cmd.none
            )


view : Model -> Html Msg
view model =
    div []
        [ inputView
        , buttonsView
        , outputView model.char
        ]


inputView : Html Msg
inputView =
    input
        [ type_ "text"
        , onInput (String.uncons
                >> Maybe.map Tuple.first
                >> Maybe.withDefault '𝔸'
                >> SetChar)
        ] []


buttonsView : Html Msg
buttonsView =
    List.map charButton badChars
        |> div []


charButton : Char -> Html Msg
charButton char =
    button
        [ onClick (SetChar char) ]
        [ text (String.fromChar char) ]


badChars : List Char
badChars =
    [ '𝔸','𝔹', '𝒜', '𝔅', '𝔄', '𝔲', '𝓉' ]


outputView : Char -> Html Msg
outputView char =
    ul []
        [ li []
            [ String.fromChar char
                |> (++) "Char: "
                |> text
            ]
        , li []
            [ Char.toCode char
                |> toString
                |> (++) "Char.toCode: "
                |> text
            ]
        , li []
            [ Char.toCode char
                |> Char.fromCode
                |> String.fromChar
                |> (++) "Char.fromCode: "
                |> text
            ]
        , li []
            [ CodePoint.fromChar char
                |> toString
                |> (++) "CodePoint.fromChar: "
                |> text
            ]
        , li []
            [ CodePoint.fromChar char
                |> CodePoint.toString
                |> (++) "CodePoint.toString: "
                |> text
            ]
        ]



main : Program Never Model Msg
main =
    Html.program
        { view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        , init = ( model, Cmd.none )
        }
