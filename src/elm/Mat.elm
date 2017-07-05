module Mat exposing (..)

import AppColors
import Color
import Color.Mixing
import Html exposing (..)
import Html.Attributes exposing (..)
import Material
import Material.Button
import Material.Icon
import Material.Options
import Model
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import Toolkit.Operators exposing (..)
import X.Html
import X.Keyboard
import X.String
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E


id =
    Material.Options.id


resourceId =
    attribute "data-btn-name" >> Material.Options.attribute


stopPropagation =
    { stopPropagation = True
    , preventDefault = False
    }


preventDefault =
    { stopPropagation = False
    , preventDefault = True
    }


stopAll =
    { stopPropagation = True
    , preventDefault = True
    }


onStopPropagation eventName =
    Material.Options.onWithOptions eventName stopPropagation


onStopPropagation2 eventName =
    D.succeed >> onStopPropagation eventName


onClickStopPropagation =
    onStopPropagation2 "click"


iconD name =
    Html.i [ class "default-color material-icons" ] [ text name ]


icon name =
    Html.i [ class "material-icons" ] [ text name ]


css =
    Material.Options.css


i =
    Material.Icon.i


iV =
    Material.Icon.view


iM icon =
    iV icon.name [ css "color" (AppColors.encode icon.color) ]


defaultBtnConfig =
    { id = ""
    , class = ""
    , classList = []
    , tabIndex = -2
    , trackingId = ""
    , primaryFAB = False
    , mdl = Material.model
    , iconProps = []
    , iconName = ""
    , msg = Model.noop
    }


many =
    Material.Options.many


primaryFAB =
    Material.Options.many
        [ Material.Button.fab
        , Material.Button.colored
        , Material.Options.cs "mdl-button--page-fab"
        ]


btn =
    Material.Button.render Model.Mdl [ 0 ]


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
                    | iconProps = c.iconProps ++ [ Material.Icon.size18 ]
                }
           )
        |> ib name clickHandler


ib iconName msg configFn =
    defaultBtnConfig |> configFn >> ibc iconName msg


ibc_ iconName msg opts =
    let
        --        trackingId =
        --            config.trackingId
        --                |> when X.String.isBlank (\_ -> "ma2-" ++ iconName)
        btnAttr =
            [ onStopPropagation2 "click" msg

            --                    , Material.Options.attribute <| attribute "data-btn-name" trackingId
            ]
                |> Material.Options.many

        --        Material.Button.icon
    in
        Material.Button.render Model.Mdl
            [ 0 ]
            Material.model
            [ btnAttr
            ]
            [ Material.Icon.view iconName [] ]


ibc iconName msg config =
    let
        trackingId =
            config.trackingId
                |> when X.String.isBlank (\_ -> "ma2-" ++ iconName)

        cs =
            [ ( config.class, config.class |> X.String.isBlank >> not )
            ]
                ++ config.classList
                |> classListAsClass

        btnAttr =
            [ nothingWhen (equals -2) tabindex config.tabIndex
            , nothingWhen X.String.isBlank Html.Attributes.id config.id
            ]
                |> List.filterMap identity
                .|> Material.Options.attribute
                |++ [ onStopPropagation2 "click" msg
                    , Material.Options.attribute <| attribute "data-btn-name" trackingId
                    ]
                |> Material.Options.many
    in
        Material.Button.render Model.Mdl
            [ 0 ]
            config.mdl
            [ Material.Options.many
                (if config.primaryFAB then
                    [ Material.Button.fab, Material.Button.colored, Material.Options.cs "mdl-button--page-fab" ]
                 else
                    [ Material.Button.icon ]
                )
            , Material.Options.cs cs
            , btnAttr
            ]
            [ Material.Icon.view iconName config.iconProps ]


classListAsClass list =
    list
        |> List.filter Tuple.second
        |> List.map Tuple.first
        |> String.join " "


bigIconTextBtn iconName textV clickHandler =
    Html.button
        [ class "big-icon-text-btn"
        , X.Html.onClickStopPropagation clickHandler
        ]
        [ Html.i [ class "material-icons" ] [ text iconName ]
        , div [] [ text textV ]
        ]


btn_ textV attributes =
    div attributes [ Html.button [ class "btn" ] [ text textV ] ]


btnFlat textV attributes =
    div attributes
        [ Html.a [ class "btn btn-flat" ] [ text textV ] ]


divider =
    div [ class "divider" ] []
