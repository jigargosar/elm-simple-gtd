module ViewModel exposing (..)

import Entity.ViewModel
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model.Types exposing (MainViewType(..))


type alias Model =
    { contexts : Entity.ViewModel.Model
    , projects : Entity.ViewModel.Model
    , viewName : String
    , mainViewType : MainViewType
    , header : { backgroundColor : String }
    }


create : Model.Types.Model -> Model
create model =
    let
        contextsVM =
            Entity.ViewModel.contexts model

        projectsVM =
            Entity.ViewModel.projects model

        mainViewType =
            model.mainViewType

        ( viewName, headerBackgroundColor ) =
            getViewInfo mainViewType projectsVM contextsVM
    in
        Model contextsVM projectsVM viewName mainViewType { backgroundColor = headerBackgroundColor }


getViewInfo mainViewType projectsVM contextsVM =
    let
        entityById id =
            List.find (.id >> equals id)

        maybeNameById id =
            entityById id >>? .name

        iconColorById id =
            entityById id >>? (.icon >> .color) >>?= sgtdBlue

        appHeaderInfoById id =
            entityById id >>? (.icon >> .color) >>?= sgtdBlue

        contextNameById id =
            contextsVM.entityList |> maybeNameById id >>? (++) "@" >>?= ""

        projectNameById id =
            projectsVM.entityList |> maybeNameById id >>? (++) "#" >>?= ""
    in
        case mainViewType of
            GroupByContextView ->
                ( contextsVM.title, contextsVM.icon.color )

            ContextView id ->
                ( contextNameById id, sgtdBlue )

            GroupByProjectView ->
                ( projectsVM.title, projectsVM.icon.color )

            ProjectView id ->
                ( projectNameById id, sgtdBlue )

            BinView ->
                ( "Bin", sgtdBlue )

            DoneView ->
                ( "Done", sgtdBlue )

            SyncView ->
                ( "Sync", sgtdBlue )


sgtdBlue =
    --paper-blue-a200
    "rgb(68, 138, 255)"
