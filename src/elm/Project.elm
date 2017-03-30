module Project exposing (..)

import PouchDB
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)


type alias Project
    = PouchDB.Document { name : ProjectName }

type alias ProjectList = List Project

type alias ProjectName = String
