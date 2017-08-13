module Mat exposing (..)

import Colors
import Html exposing (..)
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as D exposing (Decoder)
import Material
import Material.Button
import Material.Icon
import Material.Options
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import X.Html
import X.String


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



--div = Material.Options.div


id =
    Material.Options.id


attr =
    HA.attribute >>> fromHtmlAttr


fromHtmlAttr =
    Material.Options.attribute


resourceId =
    attr "data-btn-name"


tabIndex =
    HA.tabindex >> fromHtmlAttr


many =
    Material.Options.many


css =
    Material.Options.css


cs =
    Material.Options.cs


icon =
    Material.Icon.i


iconView =
    Material.Icon.view


iconSmall iconName =
    Material.Icon.view iconName [ Material.Icon.size24 ]


iconM icon =
    Material.Icon.view icon.name [ css "color" (Colors.toRBGAString icon.color) ]


fab msg mdl opts =
    btn msg [ 0 ] mdl [ Material.Button.fab, many opts ]


headerIconBtn msg mdl opts =
    btn msg [ 0 ] mdl [ many [ Material.Button.icon, cs "mdl-button--header-icon" ], many opts ]


iconBtn msg mdl opts =
    btn msg [ 0 ] mdl [ Material.Button.icon, many opts ]


btn =
    Material.Button.render


iconBtn2 msg name clickHandler =
    ib msg name clickHandler identity


iconBtn3 msg name tabIndexV clickHandler =
    ib msg name clickHandler (\c -> { c | tabIndex = tabIndexV })


iconBtn4 msg name tabIndexV className clickHandler =
    ib msg name clickHandler (\c -> { c | tabIndex = tabIndexV, class = className })


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
    }


ib msg iconName clickHandler configFn =
    defaultBtnConfig |> configFn >> ibc msg iconName clickHandler


ibc msg iconName clickHandler config =
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
            , nothingWhen X.String.isBlank HA.id config.id
            ]
                |> List.filterMap identity
                .|> Material.Options.attribute
                |++ [ onStopPropagation2 "click" clickHandler
                    , Material.Options.attribute <| HA.attribute "data-btn-name" trackingId
                    ]
                |> Material.Options.many
    in
    Material.Button.render msg
        [ 0 ]
        config.mdl
        [ Material.Options.many
            (if config.primaryFAB then
                []
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


submit textV attributes =
    div attributes [ Html.button [ HA.class "btn" ] [ text textV ] ]


btnFlat textV attributes =
    div attributes
        [ Html.button [ HA.class "btn btn-flat" ] [ text textV ] ]


divider =
    div [ HA.class "divider" ] []


modalButtonPanel config =
    let
        btn ( txt, msg ) =
            btnFlat txt [ HE.onClick msg ]
    in
    div [ HA.class "layout horizontal-reverse" ]
        (config .|> btn)


okCancelDeleteButtons config msg =
    okCancelButtonsWith config [ deleteButton msg ]


okCancelButtons config =
    okCancelButtonsWith config []


okCancelArchiveButtons config isArchived archiveMsg =
    okCancelButtonsWith config [ archiveButton isArchived archiveMsg ]


okCancelButtonsWith config list =
    div [ HA.class "layout horizontal-reverse" ]
        ([ okButton config.onSaveExclusiveModeForm
         , cancelButton config.revertExclusiveModeMsg
         ]
            ++ list
        )


okButton msg =
    btnFlat "Ok" [ HE.onClick msg ]


cancelButton msg =
    btnFlat "Cancel" [ HE.onClick msg ]


deleteButton msg =
    btnFlat "Delete" [ HE.onClick msg ]


archiveButton isArchived msg =
    btnFlat
        (if isArchived then
            "Unarchive"
         else
            "Archive"
        )
        [ HE.onClick msg ]
