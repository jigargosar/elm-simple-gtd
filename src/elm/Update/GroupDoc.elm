module Update.GroupDoc exposing (update)

import Document
import Document.Types exposing (getDocId)
import GroupDoc
import GroupDoc.FormTypes exposing (GroupDocFormMode(..))
import GroupDoc.Types exposing (..)
import Model.GroupDocStore exposing (contextStore, projectStore)
import Msg.GroupDoc exposing (..)
import Return exposing (andThen)
import Set
import Store
import Toolkit.Operators exposing (..)
import Tuple2
import Time exposing (Time)
import X.Function exposing (applyWith)
import X.Record exposing (Field, fieldLens, overT2)


type alias SubModel model =
    { model
        | projectStore : ProjectStore
        , contextStore : ContextStore
        , now : Time
    }


type alias SubReturn msg model =
    Return.Return msg (SubModel model)


type alias SubReturnF msg model =
    SubReturn msg model -> SubReturn msg model



{-
   type alias Config msg model =
       { updateEntityListCursorOnGroupDocChange : SubReturnF msg model
       }
-}


update :
    {- Config msg model
       ->
    -}
    GroupDocMsg
    -> SubReturnF msg model
update msg =
    case msg of
        OnSaveGroupDocForm form ->
            {- let
                   update fn =
                       fn form.id (GroupDoc.setName form.name)
                           |> andThen
               in
            -}
            {- case form.groupDocType of
               ContextGroupDocType ->
                   case form.mode of
                       GDFM_Add ->
                           insertContext form.name

                       GDFM_Edit ->
                           update updateContext

               ProjectGroupDocType ->
                   case form.mode of
                       GDFM_Add ->
                           insertProject form.name

                       GDFM_Edit ->
                           update updateProject
            -}
            case form.mode of
                GDFM_Add ->
                    insertGroupDoc form.groupDocType form.name

                GDFM_Edit ->
                    updateGroupDoc form.groupDocType
                        form.id
                        (GroupDoc.setName form.name)

        OnToggleContextDeleted id ->
            updateContext id Document.toggleDeleted |> andThen

        OnToggleProjectDeleted id ->
            updateProject id Document.toggleDeleted |> andThen

        OnToggleGroupDocArchived gdType id ->
            let
                _ =
                    Debug.log "\"archiving\"" ("archiving")
            in
                updateGroupDoc gdType id GroupDoc.toggleArchived

        OnToggleGroupDocDeleted gdType id ->
            updateGroupDoc gdType id Document.toggleDeleted


insertGroupDoc gdType name =
    let
        store =
            (Model.GroupDocStore.storeFieldFromGDType gdType)
    in
        andThen
            (\model ->
                overT2 store (Store.insertAndPersist (GroupDoc.init name model.now)) model
                    |> Tuple2.swap
            )



{- (\model ->
       overT2 (Model.GroupDocStore.storeFieldFromGDType gdType)
           (Store.insertAndPersist (GroupDoc.init name model.now))
           model
   )
-}
--updateContext : DocId -> (GroupDoc -> GroupDoc) -> ModelReturnF


updateContext id updateFn =
    updateAllNamedDocsDocs (Set.singleton id) updateFn contextStore



--updateProject : DocId -> (GroupDoc -> GroupDoc) -> ModelReturnF


updateProject id updateFn =
    updateAllNamedDocsDocs (Set.singleton id) updateFn projectStore


updateGroupDoc gdType id updateFn =
    updateAllGroupDocs gdType updateFn (Set.singleton id) |> andThen


updateAllGroupDocs gdType updateFn idSet model =
    overT2 (Model.GroupDocStore.storeFieldFromGDType gdType)
        (Store.updateAndPersist
            (getDocId >> Set.member # idSet)
            model.now
            updateFn
        )
        model
        |> Tuple2.swap


updateAllNamedDocsDocs idSet updateFn store model =
    overT2 store
        (Store.updateAndPersist
            (getDocId >> Set.member # idSet)
            model.now
            updateFn
        )
        model
        |> Tuple2.swap
