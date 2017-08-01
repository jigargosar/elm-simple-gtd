module Update.LaunchBar exposing (Config, update)

import Document
import ExclusiveMode.Types exposing (ExclusiveMode(XMLaunchBar))
import Fuzzy
import Models.GroupDocStore
import Overlays.LaunchBar exposing (..)
import Pages.EntityListOld exposing (..)
import Regex
import Return
import String.Extra
import Time exposing (Time)
import Toolkit.Helpers exposing (apply2)
import Toolkit.Operators exposing (..)
import Types.GroupDoc exposing (..)
import X.Return exposing (..)


type alias SubModel model =
    { model
        | projectStore : ProjectStore
        , contextStore : ContextStore
    }


type alias SubReturnF msg model =
    Return.ReturnF msg (SubModel model)


type alias SubAndThenUpdate msg model =
    msg -> SubReturnF msg model


type alias Config msg a =
    { a
        | revertExclusiveMode : msg
        , onSetExclusiveMode : ExclusiveMode -> msg
        , navigateToPathMsg : List String -> msg
    }


update :
    Config msg a
    -> Time
    -> LaunchBarMsg
    -> SubReturnF msg model
update config now msg =
    case msg of
        NOOP ->
            identity

        OnLBEnter entity ->
            let
                path =
                    case entity of
                        SI_Project project ->
                            [ "project", Document.getId project ]

                        SI_Projects ->
                            [ "projects" ]

                        SI_Context context ->
                            [ "context", Document.getId context ]

                        SI_Contexts ->
                            [ "contexts" ]
            in
            returnMsgAsCmd config.revertExclusiveMode
                >> returnMsgAsCmd (config.navigateToPathMsg path)

        OnLBInputChanged form text ->
            returnWith identity
                (\model ->
                    XMLaunchBar (updateInput now text model form)
                        |> config.onSetExclusiveMode
                        |> returnMsgAsCmd
                )

        Open ->
            now
                |> Overlays.LaunchBar.initialModel
                >> XMLaunchBar
                >> config.onSetExclusiveMode
                >> returnMsgAsCmd

        OnCancel ->
            returnMsgAsCmd config.revertExclusiveMode


type alias LaunchBarFormF =
    LaunchBarForm -> LaunchBarForm


updateInput : Time -> String -> SubModel model -> LaunchBarFormF
updateInput now input subModel form =
    let
        newInput =
            input
                |> (if now - form.updatedAt > 1 * Time.second then
                        Regex.replace (Regex.AtMost 1)
                            (Regex.regex ("^" ++ Regex.escape form.input))
                            (\_ -> "")
                    else
                        identity
                   )

        ( activeContexts, activeProjects ) =
            subModel
                |> apply2
                    ( Models.GroupDocStore.getActiveContexts
                    , Models.GroupDocStore.getActiveProjects
                    )
    in
    { form
        | searchResults = getFuzzyResults input activeContexts activeProjects
        , input = input
        , updatedAt = now
    }


fuzzyMatch needle searchItem =
    let
        --        boil = String.toLower
        boil =
            String.Extra.underscored

        boiledHay =
            searchItem |> Overlays.LaunchBar.getSearchItemName >> boil

        boiledNeedle =
            boil needle

        match n =
            Fuzzy.match [] [] n
    in
    ( searchItem, match boiledNeedle boiledHay )


getFuzzyResults needle activeContexts activeProjects =
    let
        contexts =
            activeContexts .|> SI_Context

        projects =
            activeProjects .|> SI_Project

        all =
            projects ++ contexts ++ [ SI_Projects, SI_Contexts ]
    in
    all
        .|> fuzzyMatch needle
        |> List.sortBy (Tuple.second >> .score)
