module Flow exposing (..)

import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)


type Node
    = Branch String Node Node
    | Leaf String
