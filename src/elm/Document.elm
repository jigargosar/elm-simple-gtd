module Document exposing (..)

import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


getId =
    .id


hasId id =
    getId >> equals id


equalById doc1 doc2 =
    getId doc1 == getId doc2
