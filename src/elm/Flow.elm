module Flow exposing (..)

import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)


type Branch
    = Leaf
        { question : String
        , onBack : Maybe Branch
        }
    | YesNoBranch
        { question : String
        , onBack : Maybe Branch
        , onYes : Branch
        , onNo : Branch
        }


isActionable =
    YesNoBranch
        { question = "Is it Actionable?"
        , onYes = canItBeDoneUnder2Min (\_ -> Just isActionable)
        , onNo = isItWorthKeeping (\_ -> Just isActionable)
        , onBack = Nothing
        }
        |> Debug.log "isActionable"


canItBeDoneUnder2Min back =
    Leaf
        { question = "Can it be done in less than 2 minutes ?"
        , onBack = back ()
        }


isItWorthKeeping back =
    Leaf
        { question = "Is it worth keeping ?"
        , onBack = back ()
        }
