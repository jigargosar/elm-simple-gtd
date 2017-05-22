module Stemmer exposing (stem)

{-| Stemmer is an english language stemmer, this is an Elm
implementation of the PorterStemmer taken from http://tartarus.org/~martin.

Copyright (c) 2016 Robin Luiten

Inspired by Erlang implementation on http://tartarus.org/~martin/PorterStemmer/index.html.

## Usage
@docs stem

## Implementation Details

Step numbers follow general implementation in porter stemmer implementations.

Identifier names were adopted from elrang implementation.

* **drow** stands for reverse of word
* **mets** stands for reverse of stem

-}

import Maybe exposing (withDefault, andThen)
import String

{-| Get the porter stem of a word.

Some examples and what running them produces
```
  Stemmer.stem "fullness" -- produces "full"
  Stemmer.stem "consign" -- produces "consign"
  Stemmer.stem "consigned" -- produces "consign"
  Stemmer.stem "consigning" -- produces "consign"
  Stemmer.stem "consignment" -- produces "consign"
  Stemmer.stem "knot" -- produces "knot"
  Stemmer.stem "knots" -- produces "knot"
```

-}
stem : String -> String
stem  word =
    if (String.length word) < 3 then
      word
    else
      allStepsX word


allStepsX : String -> String
allStepsX =
    String.reverse
      -- << viewParamsX "post step5"
      << step5X
      -- << viewParamsX "post step4"
      << step4X
      -- << viewParamsX "post step3"
      << step3X
      -- << viewParamsX "post step2"
      << step2X
      -- << viewParamsX "post step1"
      << step1X
      -- << viewParamsX " pre step1"
      << String.reverse


-- output trace of parameters, great for getting
-- a good view of stages if enabled in allSteps code
viewParamsX : String -> String -> String
viewParamsX context drow =
    let
      s = String.reverse drow
      _ = Debug.log("viewParams") (context, s, drow)
    in
      drow


-- gets rid of plurals and -ed or -ing.
step1X : String -> String
step1X =  step1cX << step1bX << step1aX

-- This removes plurals
step1aX : String -> String
step1aX drow =
    if String.startsWith "sess" drow then
      String.dropLeft 2 drow --  leaves "ss"
    else if String.startsWith "sei" drow then
      String.dropLeft 2 drow -- leaves "i"
    else if String.startsWith "ss" drow then
      drow -- no change
    else if String.startsWith "s" drow then
      String.dropLeft 1 drow -- removes "s"
    else
      drow


step1bX : String -> String
step1bX drow =
    if String.startsWith "dee" drow then
        if (measureX (String.dropLeft 3 drow)) > 0 then
          String.dropLeft 1 drow -- leave "ee"
        else
          drow
    else if String.startsWith "de" drow then
      let
        mets = String.dropLeft 2 drow
        -- _ = Debug.log ("step1bX") (drow, mets)
      in
        if hasVowelX mets then
          step1b2X mets
        else
          drow
    else if String.startsWith "gni" drow then
      let
        mets = String.dropLeft 3 drow
        -- _ = Debug.log ("step1bX") (drow, hasVowelX mets)
      in
        if hasVowelX mets then
          step1b2X mets
        else
          drow
    else
      drow


step1b2X : String -> String
step1b2X drow =
    -- let
    --   _ = Debug.log ("step1b2X") (drow)
    -- in
    if String.startsWith "ta" drow
       || String.startsWith "lb" drow
       || String.startsWith "zi" drow then
      String.cons 'e' drow --  add "e"
    else
      -- let
      --   _ = Debug.log ("step1b2X else") (drow)
      -- in
      case (String.uncons drow) of
        Just (h, drowTail) ->
          -- let
          --   _ = Debug.log ("step1b2X Just") (drow, h, drowTail)
          -- in
          if endsWithDoubleConsX drow
              && not (h == 'l' || h == 's' || h == 'z') then
            -- let
            --   _ = Debug.log ("step1b2X Just endsWithDoubleConsX drow")
            --     ( drow, h, drowTail, endsWithDoubleConsX drow
            --     , endsWithDoubleConsX drow
            --         && not (h == 'l' || h == 's' || h == 'z'))
            -- in
            drowTail
          else if (measureX drow) == 1 && (endsWithCVCX drow) then
            String.cons 'e' drow
          else
            drow
        Nothing ->
          drow


-- This implements porter stemmer.
-- it appears that lunr.js step 1c departs from the porter stemmer
--  lunr  stem "lay" == "lay"
--  lunr  stem "try" == "tri"
-- but porter stemmer test fixture voc.txt and output.txt state specify.
--  stem "lay" == "lai"
--  stem "try" == "try"
step1cX : String -> String
step1cX drow =
    case String.uncons drow of
      Just (c, drowTail) ->
        if (c == 'y')
           && hasVowelX drowTail then
            String.cons 'i' drowTail
        else
         drow
      Nothing ->
        drow


toR = String.reverse
step2RulesX : List (String, String)
step2RulesX =
    [ (toR "ational", toR "ate")
    , (toR "tional", toR "tion")
    , (toR "enci", toR "ence")
    , (toR "anci", toR "ance")
    , (toR "izer", toR "ize")
    , (toR "bli", toR "ble")
    , (toR "alli", toR "al")
    , (toR "entli", toR "ent")
    , (toR "eli", toR "e")
    , (toR "ousli", toR "ous")
    , (toR "ization", toR "ize")
    , (toR "ation", toR "ate")
    , (toR "ator", toR "ate")
    , (toR "alism", toR "al")
    , (toR "iveness", toR "ive")
    , (toR "fulness", toR "ful")
    , (toR "ousness", toR "ous")
    , (toR "aliti", toR "al")
    , (toR "iviti", toR "ive")
    , (toR "biliti", toR "ble")
    , (toR "logi", toR "log")
    ]


{-
maps double suffices to single ones. so -ization (-ize plus
-ation) maps to -ize etc. note that the string before the suffix must give
m() > 0
-}
step2X : String -> String
step2X drow =
    replaceStartsX 0 step2RulesX drow


step3RulesX =
    [ (toR "icate", toR "ic")
    , (toR "ative", "")
    , (toR "alize", toR "al")
    , (toR "iciti", toR "ic")
    , (toR "ical", toR "ic")
    , (toR "ful", "")
    , (toR "ness", "")
    ]


-- deals with -ic-, -full, -ness etc. similar strategy to previous step
step3X : String -> String
step3X drow =
    replaceStartsX 0 step3RulesX drow


step4RulesX =
    [ (toR "al", "")
    , (toR "ance", "")
    , (toR "ence", "")
    , (toR "er", "")
    , (toR "ic", "")
    , (toR "able", "")
    , (toR "ible", "")
    , (toR "ant", "")
    , (toR "ement", "")
    , (toR "ment", "")
    , (toR "ent", "")
    -- "ion" special case for "sion" "tion" see step4Ion
    , (toR "ou", "")
    , (toR "ism", "")
    , (toR "ate", "")
    , (toR "iti", "")
    , (toR "ous", "")
    , (toR "ive", "")
    , (toR "ize", "")
    ]


-- takes off -ant, -ence etc., in context <c>vcvc<v>
step4X : String -> String
step4X drow =
    let
      mThreshold = 1
      ionCase = "noi"
      ionLen = String.length ionCase
      drowStart = String.left ionLen drow
    in
      if (drowStart == ionCase) then -- handle (t)ion (s)ion
        step4IonX mThreshold ionLen drow
      else
        replaceStartsX mThreshold step4RulesX drow


-- handle (tion) and (sion)
step4IonX : Int -> Int -> String -> String
step4IonX mThreshold startLen drow =
    let
      afterNoi = (String.dropLeft startLen drow)
      -- _ = Debug.log("step4Ion") (mThreshold, startLen, drow)
    in
    case String.uncons afterNoi  of
      Just (char, drowEnd) ->
        -- let _ = Debug.log("step4Ion 1") (mThreshold, startLen, drow, char, drowEnd, (measureX afterNoi))
        -- in
        if (char == 't' || char == 's' )
          && (measureX afterNoi) > mThreshold then
          -- let _ = Debug.log("step4Ion 2") (mThreshold, startLen, drow, char, drowEnd, (measureX afterNoi))
          -- in
          afterNoi
        else
          drow
      Nothing ->
        drow


step5X : String -> String
step5X = step5bX << step5aX


step5aX : String -> String
step5aX drow =
    case String.uncons drow of
      Just (char, drowEnd) ->
        if char == 'e' then
          let
            m = measureX drowEnd
          in
            if m > 1 then
              drowEnd
            else if m == 1 && not (endsWithCVCX drowEnd) then
              drowEnd
            else
              drow
        else
          drow
      Nothing ->
        drow


step5bX : String -> String
step5bX drow =
    case String.uncons drow of
      Just (char, drowEnd) ->
        if (char == 'l')
            && (measureX drowEnd) > 1
            &&  endsWithDoubleConsX drow then
          drowEnd
        else
          drow
      Nothing ->
        drow


{- Return result of application of the first rule that matches input pattern
it does not have to actually change the string just match pattern.
-}
replaceStartsX : Int -> List (String, String) -> String -> String
replaceStartsX measureThreshold rules drow =
    case rules of
      r :: rs ->
        let
          (patternMatched, newDrow) = replaceStartX measureThreshold r drow
        in
          if patternMatched then
            newDrow
          else
            replaceStartsX measureThreshold rs drow
      [] ->
        drow


{-| Apply replacement rule matching start with newStart if measure threshold
is reached. In example the result patternMatched indicates the start pattern
was matched regardless of measureThreshold.

```elm
  (patterMatched, newDrow) = replaceStart measureThreshold rule drow
```
-}
replaceStartX : Int -> (String, String) -> String -> (Bool, String)
replaceStartX measureThreshold (start, newStart) drow =
    let
      startLen = String.length start
      drowStart = String.left startLen drow
    in
      if drowStart == start then
        let
          drowEnd = String.dropLeft startLen drow
          -- _ = Debug.log("replaceStart measure") (measureX drowEnd, drowEnd)
        in
          -- even if measure threshold not reached we have matched the start
          -- so the result is True for matched prefix
          if (measureX drowEnd) > measureThreshold then
            (True, String.append newStart drowEnd)
          else
            (True, drow)
      else
        (False, drow)


isVowel : Char -> Bool
isVowel = isVowelCore False


isVowelWithY : Char -> Bool
isVowelWithY = isVowelCore True


isVowelCore : Bool -> Char -> Bool
isVowelCore includeY c =
    case c of
      'a' -> True
      'e' -> True
      'i' -> True
      'o' -> True
      'u' -> True
      'y' -> if includeY then True else False
      _ -> False


{-| Implements m, the measure of a word or word part.

measures the number of consonant sequences between 0 and j. if c is
a consonant sequence and v a vowel sequence, and <..> indicates arbitrary
presence,

    <c><v>       gives 0
    <c>vc<v>     gives 1
    <c>vcvc<v>   gives 2
    <c>vcvcvc<v> gives 3
     ....

Input word in this implementation is reversed, so correct it is
restored to forward to calculate measure.
-}
measureX : String -> Int
measureX drow =
    let
      word = String.reverse drow
      -- _ = Debug.log("measure forward word") (word)
    in
      case (String.uncons word) of
        Just (h, wordTail) ->
          case isVowel h of
            True -> foundVowelX wordTail 0
            False -> foundLeadingConsonantX wordTail
        Nothing ->
          0

foundLeadingConsonantX : String -> Int
foundLeadingConsonantX word =
    case (String.uncons word) of
      Just (h, wordTail) ->
        case isVowelWithY h of
          True -> foundVowelX wordTail 0
          False -> foundLeadingConsonantX wordTail
      Nothing ->
        0


foundVowelX : String -> Int -> Int
foundVowelX word m =
    case (String.uncons word) of
      Just (h, wordTail) ->
        case isVowel h of
          True -> foundVowelX wordTail m
          False -> foundConsonantX wordTail (m + 1)
      Nothing ->
        m


foundConsonantX : String -> Int -> Int
foundConsonantX word m =
    case (String.uncons word) of
      Just (h, wordTail) ->
        case isVowelWithY h of
          True -> foundVowelX wordTail m
          False -> foundConsonantX wordTail m
      Nothing ->
        m


-- Implements *v* - the stem contains a vowel
hasVowelX : String -> Bool
hasVowelX drow =
    case (String.uncons (String.reverse drow)) of
      Just (h, wordTail) ->
        case isVowel h of
          True -> True
          False -> hasVowel2X wordTail
      Nothing ->
        False


hasVowel2X : String -> Bool
hasVowel2X word =
    case (String.uncons word) of
      Just (h, wordTail) ->
        case isVowelWithY h of
          True -> True
          False -> hasVowel2X wordTail
      Nothing ->
        False


-- Implements *d - the stem ends with a double consonant.
endsWithDoubleConsX : String -> Bool
endsWithDoubleConsX drow =
    case String.uncons drow of
      Just (c1, drowTail) ->
        if not (isVowelWithY c1) then
          case String.uncons drowTail of
            Just (c2, drowTail2) ->
              c1 == c2
            Nothing ->
              False
        else
          False
      Nothing ->
        False


-- Implements *o - the stem ends cvc, where the second c is not w, x, or y.
endsWithCVCX : String -> Bool
endsWithCVCX drow =
    case String.uncons drow of
      Just (c2, drowTail1) ->
        if not ((isVowel c2) || (c2 == 'w') || (c2 == 'x') || (c2 == 'y')) then
          case String.uncons drowTail1 of
            Just (v, drowTail2) ->
              if (isVowelWithY v) then
                case String.uncons drowTail2 of
                  Just (c1, drowTail3) ->
                    -- let
                    --   _ = Debug.log ("endsWithCVCX") (drow, c2, v, c1)
                    -- in
                    not (isVowel c1)
                  Nothing ->
                    False
              else
                False
            Nothing ->
              False
        else
          False
      Nothing ->
        False
