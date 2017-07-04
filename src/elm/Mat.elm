module Mat exposing (..)

import AppColors
import Color
import Color.Mixing
import Html exposing (..)
import Html.Attributes exposing (..)
import Model
import X.Function exposing (when)
import X.Function.Infix exposing (..)
import X.Html exposing (onClickStopPropagation)
import X.Keyboard
import X.String


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
    { id : String
    , class : String
    , classList : List ( String, Bool )
    , iconName : String
    , onClick : Model.Msg
    , tabIndex : Int
    , trackingId : String
    }


defaultBtnConfig =
    { id = ""
    , class = ""
    , classList = []
    , iconName = ""
    , msg = Model.noop
    , tabIndex = -1
    , trackingId = ""
    }


iconBtnWithConfig config =
    let
        trackingId =
            config.trackingId
                |> when X.String.isBlank (\_ -> "ma-" ++ config.iconName)
    in
        a
            [ id config.id
            , class ("icon-button btn-flat btn-floating " ++ config.class)
            , onClickStopPropagation config.msg
            , tabindex config.tabIndex
            , X.Keyboard.onEnter config.msg
            , attribute "data-btn-name" trackingId
            ]
            [ i
                [ class "material-icons"
                ]
                [ text config.iconName ]
            ]


iconBtn configFn =
    iconBtnWithConfig (configFn defaultBtnConfig)


iconBtn2 name clickHandler =
    iconBtn (\c -> { c | iconName = name, msg = clickHandler })


iconBtn3 name tabIndexV clickHandler =
    iconBtn (\c -> { c | iconName = name, msg = clickHandler, tabIndex = tabIndexV })


iconBtn4 name tabIndexV className clickHandler =
    iconBtn
        (\c ->
            { c
                | iconName = name
                , msg = clickHandler
                , tabIndex = tabIndexV
                , class = className
            }
        )


smallIconBtn configFn =
    iconBtn (configFn >> (\c -> { c | class = c.class ++ " x24" }))


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
