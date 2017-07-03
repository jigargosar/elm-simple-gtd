module Material exposing (..)

import AppColors
import Html exposing (..)
import Html.Attributes exposing (..)
import X.Function.Infix exposing (..)
import X.Html exposing (onClickStopPropagation)


iconD name =
    i [ class "default-color material-icons" ] [ text name ]


icon name =
    i [ class "material-icons" ] [ text name ]


iconA name attrs =
    let
        allAttr =
            class "material-icons" :: attrs
    in
        i allAttr [ text name ]


iconM icon =
    iconA icon.name [ style [ "color" => AppColors.encode icon.color ] ]


iconBtn name attributes =
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


bigIconTextBtn iconName textV clickHandler =
    Html.button
        [ class "big-button layout vertical center upper-case"
        , onClickStopPropagation clickHandler
        ]
        [ i [ class "material-icons" ] [ text iconName ]
        , div [] [ text textV ]
        ]


fab iconName btnName otherAttr =
    let
        allAttr =
            btnAttr "btn-floating x-fab" btnName otherAttr
    in
        Html.button allAttr [ icon iconName ]


btnAttr btnClass btnName otherAttr =
    [ class btnClass, attribute "data-btn-name" btnName ] ++ otherAttr


divider =
    div [ class "divider" ] []


button textV attributes =
    div attributes [ Html.button [ class "btn" ] [ text textV ] ]


buttonFlat textV attributes =
    div attributes
        [ Html.button [ class "btn btn-flat" ] [ text textV ] ]
