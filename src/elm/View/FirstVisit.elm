module View.FirstVisit exposing (..)

import AppUrl
import Model
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import X.Html exposing (onClickStopPropagation)


overlay =
    div
        [ class "overlay"
        , onClickStopPropagation Model.noop
        ]
        [ div [ id "welcome", class "modal fixed-center" ]
            [ div [ class "modal-content" ]
                [ p [] [ text "One Click Signup" ]
                , div [ class "divider" ] []
                , div [ class "row section" ]
                    [ div [ class "col s12 m6" ]
                        [ span [ class "flow-text" ]
                            [ text "Already have an account with us?" ]
                        ]
                    , div [ class "col s12 m6" ]
                        [ a [ onClick Model.OnSignIn ]
                            [ img [ class "google-sign-in", src AppUrl.googleSignInImage2X ] []
                            ]
                        ]
                    ]
                , div [ class "divider" ] []
                , div [ class "row section" ]
                    [ div [ class "col s12 m6" ]
                        [ span [ class "flow-text" ]
                            [ text "Or lets" ]
                        ]
                    , div [ class "col s12 m6" ]
                        [ a [ class "btn", onClick Model.OnCreateDefaultEntities ]
                            [ text "Get Started" ]
                        ]
                    ]
                ]
            , div [ class "divider" ] []
            , div [ class "right-align" ]
                [ a [ class "btn btn-flat", onClick Model.OnDeactivateEditingMode ]
                    [ text "Skip creating sample items" ]
                ]
            ]
        ]
