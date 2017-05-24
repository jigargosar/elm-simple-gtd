module EntityList.ViewModel exposing (..)

import Document
import Entity exposing (Entity)
import EntityList.GroupViewModel
import Html
import Html.Attributes exposing (tabindex)
import Model
import Msg exposing (Msg)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Todo.View exposing (TodoViewModel)


type ViewModel
    = Group EntityList.GroupViewModel.ViewModel
    | Todo TodoViewModel


type alias EntityViewModel =
    { id : Document.Id
    , onFocusIn : Msg
    , onFocus : Msg
    , onBlur : Msg
    , startEditingMsg : Msg
    , toggleDeleteMsg : Msg
    , startEditingMsg : Msg
    , tabIndexAV : Html.Attribute Msg
    }


getTabindexAV focused =
    let
        tabindexValue =
            if focused then
                0
            else
                -1
    in
        tabindex tabindexValue


isEntityFocusedInEntityList entityList viewModel =
    let
        focusedId =
            entityList
                |> List.find (Model.getEntityId >> equals viewModel.focusedEntityInfo.id)
                |> Maybe.orElse (List.head entityList)
                ?|> Model.getEntityId
                ?= ""
    in
        Model.getEntityId >> equals focusedId


create : Entity.ListViewType -> Model.Model -> List ViewModel
create viewType model =
    let
        entityList =
            Model.createViewEntityList viewType model
    in
        []
