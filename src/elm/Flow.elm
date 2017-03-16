module Flow exposing (..)


type Branch
    = Leaf
        { questionText : String
        , onBack : () -> Maybe Branch
        }
    | YesNoBranch
        { questionText : String
        , onBack : Maybe Branch
        , onYes : Branch
        , onNo : Branch
        }


isActionable =
    YesNoBranch
        { questionText = "Is it Actionable?"
        , onYes = canItBeDoneUnder2Min
        , onNo = isItWorthKeeping
        , onBack = Nothing
        }


canItBeDoneUnder2Min =
    Leaf
        { questionText = "Can it be done in less than 2 minutes ?"
        , onBack = (\_ -> Just isActionable)
        }


isItWorthKeeping =
    Leaf
        { questionText = "Is it worth keeping ?"
        , onBack = (\_ -> Just isActionable)
        }
