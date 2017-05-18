module StemmerTests exposing (..)

import Expect
import Test exposing (..)

import Stemmer


{-| Test Stemmer, many many less tests than StemmerTestsFullPorter.elm..
So runs must faster, but it does cover the cases discovered porting stemmer
Elm.
-}
type alias StemCase = (String, String)


tests : Test
tests =
  describe "Stemmer Tokenizer tests" <|
    List.map testStemmer stemmingFixture


testStemmer : StemCase -> Test
testStemmer (word, expectedStem) =
  test ("stem " ++ word ++ " to " ++ expectedStem ++ " ") <|
    \() -> Expect.equal expectedStem (Stemmer.stem word)


stemmingFixture : List StemCase
stemmingFixture =
  [ ( "consign", "consign" )
  , ( "consigned", "consign" )
  , ( "consigning", "consign" )
  , ( "consignment", "consign" )
  , ( "consist", "consist" )
  , ( "consisted", "consist" )
  , ( "consistency", "consist" )
  , ( "consistent", "consist" )
  , ( "consistently", "consist" )
  , ( "consisting", "consist" )
  , ( "consists", "consist" )
  , ( "consolation", "consol" )
  , ( "consolations", "consol" )
  , ( "consolatory", "consolatori" )
  , ( "console", "consol" )
  , ( "consoled", "consol" )
  , ( "consoles", "consol" )
  , ( "consolidate", "consolid" )
  , ( "consolidated", "consolid" )
  , ( "consolidating", "consolid" )
  , ( "consoling", "consol" )
  , ( "consols", "consol" )
  , ( "consonant", "conson" )
  , ( "consort", "consort" )
  , ( "consorted", "consort" )
  , ( "consorting", "consort" )
  , ( "conspicuous", "conspicu" )
  , ( "conspicuously", "conspicu" )
  , ( "conspiracy", "conspiraci" )
  , ( "conspirator", "conspir" )
  , ( "conspirators", "conspir" )
  , ( "conspire", "conspir" )
  , ( "conspired", "conspir" )
  , ( "conspiring", "conspir" )
  , ( "constable", "constabl" )
  , ( "constables", "constabl" )
  , ( "constance", "constanc" )
  , ( "constancy", "constanc" )
  , ( "constant", "constant" )
  , ( "knack", "knack" )
  , ( "knackeries", "knackeri" )
  , ( "knacks", "knack" )
  , ( "knag", "knag" )
  , ( "knave", "knave" )
  , ( "knaves", "knave" )
  , ( "knavish", "knavish" )
  , ( "kneaded", "knead" )
  , ( "kneading", "knead" )
  , ( "knee", "knee" )
  , ( "kneel", "kneel" )
  , ( "kneeled", "kneel" )
  , ( "kneeling", "kneel" )
  , ( "kneels", "kneel" )
  , ( "knees", "knee" )
  , ( "knell", "knell" )
  , ( "knelt", "knelt" )
  , ( "knew", "knew" )
  , ( "knick", "knick" )
  , ( "knif", "knif" )
  , ( "knife", "knife" )
  , ( "knight", "knight" )
  , ( "knights", "knight" )
  , ( "knit", "knit" )
  , ( "knits", "knit" )
  , ( "knitted", "knit" )
  , ( "knitting", "knit" )
  , ( "knives", "knive" )
  , ( "knob", "knob" )
  , ( "knobs", "knob" )
  , ( "knock", "knock" )
  , ( "knocked", "knock" )
  , ( "knocker", "knocker" )
  , ( "knockers", "knocker" )
  , ( "knocking", "knock" )
  , ( "knocks", "knock" )
  , ( "knopp", "knopp" )
  , ( "knot", "knot" )
  , ( "knots", "knot" )

  -- , ( "lay", "lay" )  -- lunr.js step 1c different to porter here
  -- , ( "try", "tri" )  -- lunr.js step 1c different to porter here
  , ( "lay", "lai" ) -- the porter stemmer specification
  , ( "try", "try" ) -- the porter stemmer specification

  -- added 1 and 2 char word to exercise < 3 no change
  , ( "a", "a" )
  , ( "as", "as" )

  -- extra tests from porter stemmer, these 3 cases each uncovered a subtle bug in solution
  , ( "achilles", "achil" )
  , ( "agreement", "agreement" )
  , ( "baying", "bai" )
  , ( "abruption", "abrupt" )
  , ( "additions", "addit" )
  , ( "crying", "cry" )

  ]
