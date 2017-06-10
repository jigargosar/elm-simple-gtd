module Main exposing (..)

import Html exposing (..)
import Keyboard.Combo


main : Program Never Model Msg
main =
    Html.program
        { subscriptions = subscriptions
        , init = init
        , update = update
        , view = view
        }


keyboardCombos : List (Keyboard.Combo.KeyCombo Msg)
keyboardCombos =
    [ Keyboard.Combo.combo2 ( Keyboard.Combo.control, Keyboard.Combo.s ) Save
    , Keyboard.Combo.combo2 ( Keyboard.Combo.control, Keyboard.Combo.a ) SelectAll
    , Keyboard.Combo.combo3 ( Keyboard.Combo.control, Keyboard.Combo.alt, Keyboard.Combo.e ) RandomThing
    ]



-- Init


init : ( Model, Cmd Msg )
init =
    { keys =
        Keyboard.Combo.init
            { toMsg = ComboMsg
            , combos = keyboardCombos
            }
    , content = "No combo yet"
    }
        ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    Keyboard.Combo.subscriptions model.keys



-- Model


type alias Model =
    { keys : Keyboard.Combo.Model Msg
    , content : String
    }



-- Update


type Msg
    = Save
    | SelectAll
    | RandomThing
    | ComboMsg Keyboard.Combo.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Save ->
            { model | content = "Saved" } ! []

        SelectAll ->
            { model | content = "Select All" } ! []

        RandomThing ->
            { model | content = "Random Thing" } ! []

        ComboMsg msg ->
            let
                ( updatedKeys, comboCmd ) =
                    Keyboard.Combo.update msg model.keys
            in
                ( { model | keys = updatedKeys }, comboCmd )



-- View


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "Available Key Commands:" ]
        , ul []
            [ li [] [ text "Save: Ctrl+s" ]
            , li [] [ text "Select All: Ctrl+a" ]
            , li [] [ text "Random Thing: Ctrl+Alt+e" ]
            ]
        , div []
            [ strong [] [ text "Current command: " ]
            , span [] [ text model.content ]
            ]
        ]
