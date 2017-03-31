module Project exposing (..)

import PouchDB
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)
import Random.Pcg as Random exposing(..)
import RandomIdGenerator


type alias Project =
    PouchDB.Document { name : ProjectName }


type alias ProjectList =
    List Project


type alias ProjectName =
    String


type alias ProjectId =
    String


nameEquals name =
    getName >> equals name


getName =
    .name


getId =
    .id


create name =
    { id = "", rev = "", name = name }

initWithNameAndId name id =
    { id = id, rev = "", name = name }


projectGenerator name =
    Random.map (initWithNameAndId name) RandomIdGenerator.idGen

