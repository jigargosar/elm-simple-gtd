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
    , primaryFAB : Bool
    }


defaultBtnConfig =
    { id = ""
    , class = ""
    , classList = []
    , iconName = ""
    , msg = Model.noop
    , tabIndex = -1
    , trackingId = ""
    , primaryFAB = False
    }


iconBtnWithConfig config =
    let
        trackingId =
            config.trackingId
                |> when X.String.isBlank (\_ -> "ma-" ++ config.iconName)

        classListV =
            [ ( "icon-button btn-floating", True )
            , ( "btn-flat", not config.primaryFAB )
            , ( "x-primaryFAB", config.primaryFAB )
            , ( config.class, config.class |> X.String.isBlank >> not )
            ]
                ++ config.classList
    in
        a
            [ id config.id
            , classList classListV
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


primaryFAB iconName msg configFn =
    ib iconName msg <| configFn >> (\c -> { c | primaryFAB = True })


iconBtn2 name clickHandler =
    iconBtn (\c -> { c | iconName = name, msg = clickHandler })



--    ib name clickHandler identity


ib iconName msg configFn =
    defaultBtnConfig |> configFn >> (\c -> { c | iconName = iconName, msg = msg }) >> ibc


ibc config =
    let
        trackingId =
            config.trackingId
                |> when X.String.isBlank (\_ -> "ma-" ++ config.iconName)

        classListV =
            [ ( "IB", True )
            , ( "IB_PrimaryFAB", config.primaryFAB )
            , ( config.class, config.class |> X.String.isBlank >> not )
            ]
                ++ config.classList
    in
        a
            [ id config.id
            , classList classListV
            , onClickStopPropagation config.msg
            , tabindex config.tabIndex
            , X.Keyboard.onEnter config.msg
            , attribute "data-btn-name" trackingId
            ]
            [ i
                [ classList
                    [ ( "IB__I", True )
                    , ( "IB__I_PrimaryFAB", config.primaryFAB )
                    ]
                ]
                [ text config.iconName ]
            ]


smallIconBtn configFn =
    configFn
        >> (\c ->
                { c
                    | classList = c.classList ++ [ ( "x24", True ) ]
                }
           )
        |> iconBtn


classListAsClass list =
    list
        |> List.filter Tuple.second
        |> List.map Tuple.first
        |> String.join " "


bigIconTextBtn iconName textV clickHandler =
    Html.button
        [ class "big-icon-text-btn"
        , onClickStopPropagation clickHandler
        ]
        [ i [ class "material-icons" ] [ text iconName ]
        , div [] [ text textV ]
        ]


btn textV attributes =
    div attributes [ Html.button [ class "btn" ] [ text textV ] ]


btnFlat textV attributes =
    div attributes
        [ Html.a [ class "btn btn-flat" ] [ text textV ] ]


divider =
    div [ class "divider" ] []
