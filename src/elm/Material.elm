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


iconA__ name attrs =
    let
        allAttr =
            class "material-icons" :: attrs
    in
        i allAttr [ text name ]


iconM icon =
    iconA__ icon.name [ style [ "color" => AppColors.encode icon.color ] ]


iconBtnC name className =
    Html.button
        [ class ("btn-flat btn-floating " ++ className)
        ]
        [ i [ class "default-color material-icons" ] [ text name ] ]


iconBtnD name clickHandler =
    Html.button
        [ class "btn-flat btn-floating"
        , onClickStopPropagation clickHandler
        ]
        [ i [ class "default-color material-icons" ] [ text name ] ]


iconBtnDT name tabIndexAV clickHandler =
    Html.button
        [ class "btn-flat btn-floating"
        , tabIndexAV
        , onClickStopPropagation clickHandler
        ]
        [ i [ class "default-color material-icons" ] [ text name ] ]


iconBtnDTC name tabIndexAV className clickHandler =
    Html.button
        [ class ("btn-flat btn-floating " ++ className)
        , tabIndexAV
        , onClickStopPropagation clickHandler
        ]
        [ i [ class "default-color material-icons" ] [ text name ] ]


iconButtonA name tabIndexAV attributes =
    div attributes
        [ Html.button
            [ class "btn-flat btn-floating"
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
        [ class "big-icon-text-btn"
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
