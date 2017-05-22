{-| Create an index and add a document, search a document
This variation indexes words from a field which is List String.

Copyright (c) 2016 Robin Luiten
-}

import ElmTextSearch
import Html exposing (Html, div, text)


{-| Example document type. -}
type alias ExampleDocType =
  { cid : String
  , title : String
  , author : String
  , body : List String
  }


{-| Create an index with default configuration.
See ElmTextSearch.SimpleConfig documentation for parameter information.
-}
createNewIndexExample : ElmTextSearch.Index ExampleDocType
createNewIndexExample =
  ElmTextSearch.new
    { ref = .cid
    , fields =
        [ ( .title, 5.0 )
        ]
    , listFields =
        [ ( .body, 1.0)
        ]
    }


{-| Add a document to an index. -}
resultUpdatedMyIndexAfterAdd :
  Result String (ElmTextSearch.Index ExampleDocType)
resultUpdatedMyIndexAfterAdd =
  ElmTextSearch.add
    { cid = "id1"
    , title = "First Title"
    , author = "Some Author"
    , body =
      [ "Words in this example "
      , "document with explanations."
      ]
    }
    createNewIndexExample


{-| Search the index.

The result includes an updated Index because a search causes internal
caches to be updated to improve overall performance.
-}
resultSearchIndex :
  Result String
    ( ElmTextSearch.Index ExampleDocType
    , List (String, Float)
    )
resultSearchIndex =
  resultUpdatedMyIndexAfterAdd
    |> Result.andThen
      (ElmTextSearch.search "explanations")


{-| Display search result. -}
main =
  let
    -- want only the search results not the returned index
    searchResults = Result.map Tuple.second resultSearchIndex
  in
    div []
      [ text
          (
            "Result of searching for \"explanations\" is "
              ++ (toString searchResults)
          )
      ]
