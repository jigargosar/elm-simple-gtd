module Mat exposing (..)

import AppColors
import Color
import Color.Mixing
import Html exposing (..)
import Html.Attributes
import Html.Attributes as HA
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


onWithOptions =
    Material.Options.onWithOptions


onStopPropagation eventName =
    onWithOptions eventName stopPropagation


onStopPropagation2 eventName =
    D.succeed >> onStopPropagation eventName


onClickStopPropagation =
    onStopPropagation2 "click"


id =
    Material.Options.id


attr =
    Html.Attributes.attribute >>> fromHtmlAttr


fromHtmlAttr =
    Material.Options.attribute


resourceId =
    attr "data-btn-name"


tabIndex =
    Html.Attributes.tabindex >> fromHtmlAttr


many =
    Material.Options.many


css =
    Material.Options.css


cs =
    Material.Options.cs


icon =
    Material.Icon.i


iconSmall iconName =
    Material.Icon.view iconName [ Material.Icon.size24 ]


iconM icon =
    Material.Icon.view icon.name [ css "color" (AppColors.encode icon.color) ]


primaryFAB =
    many
        [ Material.Button.fab
        , Material.Button.colored
        , cs "mdl-button--page-fab"
        ]


headerIconBtn mdl opts =
    btn mdl [ many [ Material.Button.icon, cs "mdl-button--header-icon" ], many opts ]


iconBtn mdl opts =
    btn mdl [ Material.Button.icon, many opts ]


btn =
    Material.Button.render Model.Mdl [ 0 ]


iconBtn2 name clickHandler =
    ib name clickHandler identity


iconBtn3 name tabIndexV clickHandler =
    ib name clickHandler (\c -> { c | tabIndex = tabIndexV })


iconBtn4 name tabIndexV className clickHandler =
    ib name clickHandler (\c -> { c | tabIndex = tabIndexV, class = className })


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
            [ nothingWhen (equals -2) HA.tabindex config.tabIndex
            , nothingWhen X.String.isBlank Html.Attributes.id config.id
            ]
                |> List.filterMap identity
                .|> Material.Options.attribute
                |++ [ onStopPropagation2 "click" msg
                    , Material.Options.attribute <| Html.Attributes.attribute "data-btn-name" trackingId
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
        [ HA.class "big-icon-text-btn"
        , X.Html.onClickStopPropagation clickHandler
        ]
        [ Html.i [ HA.class "material-icons" ] [ text iconName ]
        , div [] [ text textV ]
        ]


btn_ textV attributes =
    div attributes [ Html.button [ HA.class "btn" ] [ text textV ] ]


btnFlat textV attributes =
    div attributes
        [ Html.button [ HA.class "btn btn-flat" ] [ text textV ] ]


divider =
    div [ HA.class "divider" ] []
