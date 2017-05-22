module Trie.Json.Decoder exposing (decoder)

{-| Json Decoder for Trie

@docs decoder

Copyright (c) 2016 Robin Luiten
-}

import Dict exposing ( Dict )
import Json.Decode as Decode
import String

import TrieModel exposing ( Trie(..) )


{-| A Trie Decoder -}
decoder : Decode.Decoder a -> Decode.Decoder (Trie a)
decoder valDec =
  Decode.oneOf
  [ Decode.null EmptyTrie
  , decoderTrie valDec
  ]


decoderTrie : Decode.Decoder a -> Decode.Decoder (Trie a)
decoderTrie valDec =
  Decode.oneOf
  [ Decode.map ValNode (decoderValDict valDec)
  , Decode.map TrieNode (Decode.lazy (\_ -> decoderTrieDict valDec))
  , Decode.map ValTrieNode (Decode.lazy (\_ -> decoderValTrieNode valDec))
  , Decode.fail "Invalid Trie Structure found."
  ]


decoderValDict : Decode.Decoder a -> Decode.Decoder (Dict String a)
decoderValDict =
  Decode.dict


decoderTrieDict : Decode.Decoder a -> Decode.Decoder (Dict String (Trie a))
decoderTrieDict valDec =
  Decode.dict (decoder valDec)


decoderValTrieNode : Decode.Decoder a -> Decode.Decoder (Dict String a, Dict String (Trie a))
decoderValTrieNode valDec =
  Decode.map2 (,)
    (Decode.index 0 (decoderValDict valDec))
    (Decode.index 1 (decoderTrieDict valDec))
