module Notification exposing (..)

import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


type alias Response =
    { action : String
    , data : { id : String }
    }


type alias Request =
    { tag : String
    , title : String
    , body : String
    , actions : List { title : String, action : String }
    , data :
        { id : String
        , notificationClickedPort : String
        , skipFocusActionList : List String
        }
    }
