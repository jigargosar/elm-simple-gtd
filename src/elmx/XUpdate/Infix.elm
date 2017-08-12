module XUpdate.Infix exposing (..)

import XUpdate


(:>) =
    flip XUpdate.map



--infixl 0 :>


(::>) =
    flip XUpdate.andThen
infixl 0 ::>


(+>) =
    flip XUpdate.addCmd
infixl 0 +>


(+:>) =
    flip XUpdate.addEffect
infixl 0 +:>


(?+:>) =
    flip XUpdate.maybeAddEffect
infixl 0 ?+:>
