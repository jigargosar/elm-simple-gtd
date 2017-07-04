module Mat exposing (..)

import AppColors
import Color
import Color.Mixing
import Html exposing (..)
import Html.Attributes exposing (..)
import Model
import X.Function.Infix exposing (..)
import X.Html exposing (onClickStopPropagation)
import X.Keyboard


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


type alias BtnConfig =
    { class : String
    , classList : List ( String, Bool )
    , iconName : String
    , onClick : Model.Msg
    , tabIndex : Int
    }


defaultBtnConfig =
    { class = ""
    , classList = []
    , iconName = ""
    , msg = Model.noop
    , tabIndex = -1
    }


iconBtnWithConfig config =
    a
        [ class ("icon-button btn-flat btn-floating " ++ config.class)
        , onClickStopPropagation config.msg
        , tabindex config.tabIndex
        , X.Keyboard.onEnter config.msg
        ]
        [ i
            [ class "material-icons"
            ]
            [ text config.iconName ]
        ]


iconBtn configFn =
    iconBtnWithConfig (configFn defaultBtnConfig)


iconBtnD name clickHandler =
    iconBtn (\c -> { c | iconName = name, msg = clickHandler })


iconBtnDT name tabIndexV clickHandler =
    iconBtn (\c -> { c | iconName = name, msg = clickHandler, tabIndex = tabIndexV })


iconBtnDTC name tabIndexAV className clickHandler =
    Html.button
        [ class ("btn-flat btn-floating " ++ className)
        , tabindex tabIndexAV
        , onClickStopPropagation clickHandler
        ]
        [ i [ class "default-color material-icons" ] [ text name ] ]


iconButtonA name tabIndexAV attributes =
    div attributes
        [ Html.button
            [ class "btn-flat btn-floating"
            , tabindex tabIndexAV
            ]
            [ i [ class "default-color material-icons" ] [ text name ] ]
        ]


smallIconButtonTIAV name tabIndexAV attributes =
    div attributes
        [ Html.button
            [ class "btn-flat btn-floating x24"
            , style [ "z-index" => "0" ]
            , tabindex tabIndexAV
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
        [ Html.a [ class "btn btn-flat" ] [ text textV ] ]
