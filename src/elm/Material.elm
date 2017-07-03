module Material exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import X.Function.Infix exposing (..)
import X.Html exposing (onClickStopPropagation)


icon name =
    i [ class "default-color material-icons" ] [ text name ]


iconA name attr =
    div attr [ i [ class "material-icons" ] [ text name ] ]


iconButton name attributes =
    div attributes
        [ Html.button
            [ class "btn-flat btn-floating"
            , style [ "z-index" => "0" ]
            ]
            [ i [ class "default-color material-icons" ] [ text name ] ]
        ]


iconButtonTIAV name tabIndexAV attributes =
    div attributes
        [ Html.button
            [ class "btn-flat btn-floating"
            , style [ "z-index" => "0" ]
            , tabIndexAV
            ]
            [ i [ class "default-color material-icons" ] [ text name ] ]
        ]


smallIconButtonTIAV name tabIndexAV attributes =
    div attributes
        [ Html.button
            [ class "btn-flat btn-floating x24"
            , style [ "z-index" => "0" ]
            , tabIndexAV
            ]
            [ i [ class "default-color material-icons" ] [ text name ] ]
        ]


bigIconTextButton iconName textV clickHandler =
    a
        [ class "big-button layout vertical center upper-case"
        , onClickStopPropagation clickHandler
        ]
        [ i [ class "material-icons" ] [ text iconName ]
        , div [] [ text textV ]
        ]


fab name attributes =
    let
        allAttr =
            [ class "btn-floating" ] ++ attributes
    in
        Html.button allAttr
            [ i [ class "material-icons", style [ "color" => "white" ] ] [ text name ] ]


divider =
    div [ class "divider" ] []


button textV attributes =
    div attributes [ Html.button [ class "btn" ] [ text textV ] ]


buttonFlat textV attributes =
    div attributes
        [ Html.button [ class "btn btn-flat" ] [ text textV ] ]
