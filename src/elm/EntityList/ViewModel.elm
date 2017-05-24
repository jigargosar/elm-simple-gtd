module EntityList.ViewModel exposing (..)

import Document
import Entity exposing (Entity)
import EntityList.GroupViewModel
import Html
import Model
import Msg exposing (Msg)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Todo.View exposing (TodoViewModel)


type alias ViewModel =
    { entityList : List Entity
    }


type EntityViewModelWrapper
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


create : Entity.ListViewType -> Model.Model -> ViewModel
create viewType model =
    let
        entityList =
            Model.createViewEntityList viewType model
    in
        { entityList = Model.createViewEntityList viewType model }
