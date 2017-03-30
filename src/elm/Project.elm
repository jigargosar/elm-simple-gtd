module Project exposing (..)

import PouchDB
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)


type alias Project
    = PouchDB.Document { name : String }

type alias ProjectList = List Project

