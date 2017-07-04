module Mat exposing (..)

import AppColors
import Color
import Color.Mixing
import Html exposing (..)
import Html.Attributes exposing (..)
import Model
import X.Function exposing (..)
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
    , tabIndex = -2
    , trackingId = ""
    , primaryFAB = False
    }


primaryFAB iconName msg configFn =
    ib iconName msg <| configFn >> (\c -> { c | primaryFAB = True })


iconBtn2 name clickHandler =
    ib name clickHandler identity


iconBtn3 name tabIndexV clickHandler =
    ib name clickHandler (\c -> { c | tabIndex = tabIndexV })


iconBtn4 name tabIndexV className clickHandler =
    ib name clickHandler (\c -> { c | tabIndex = tabIndexV, class = className })


smallIconBtn name clickHandler configFn =
    configFn
        >> (\c ->
                { c
                    | classList = c.classList ++ [ ( "x24", True ) ]
                }
           )
        |> ib name clickHandler


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

        optionalAttr =
            [ nothingWhen (equals -2) tabindex config.tabIndex
            , nothingWhen X.String.isBlank id config.id
            ]
                |> List.filterMap identity
    in
        a
            ([ classList classListV
             , onClickStopPropagation config.msg
             , X.Keyboard.onEnter config.msg
             , attribute "data-btn-name" trackingId
             ]
                ++ optionalAttr
            )
            [ i
                [ classList
                    [ ( "IB__I", True )
                    , ( "IB__I_PrimaryFAB", config.primaryFAB )
                    ]
                ]
                [ text config.iconName ]
            ]


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
