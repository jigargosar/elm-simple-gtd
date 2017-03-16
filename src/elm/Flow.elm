module Flow exposing (..)


type Branch
    = Leaf
        { question : String
        , onBack : () -> Maybe Branch
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
        , onYes = canItBeDoneUnder2Min
        , onNo = isItWorthKeeping
        , onBack = Nothing
        }


canItBeDoneUnder2Min =
    Leaf
        { question = "Can it be done in less than 2 minutes ?"
        , onBack = (\_ -> Just isActionable)
        }


isItWorthKeeping =
    Leaf
        { question = "Is it worth keeping ?"
        , onBack = (\_ -> Just isActionable)
        }
