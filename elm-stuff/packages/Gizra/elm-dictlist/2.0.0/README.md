[![Build Status](https://travis-ci.org/Gizra/elm-dictlist.svg?branch=master)](https://travis-ci.org/Gizra/elm-dictlist)

# elm-dictlist

Have you ever wanted a `Dict`, but you need to maintain an arbitrary
ordering of keys? Or, a `List`, but you want to efficiently lookup values
by a key? With `DictList`, now you can!

`DictList` implements the full API for `Dict` (and should be a drop-in
replacement for it). However, instead of ordering things from lowest
key to highest key, it allows for an arbitrary ordering.

We also implement most of the API for `List`. However, the API is not
identical, since we need to account for both keys and values.

But there's more! What if you would like a dictionary with keys that are
not comparable, using
[eeue56/elm-all-dict](http://package.elm-lang.org/packages/eeue56/elm-all-dict/latest)?
We have thought of you, too, with `AllDictList` and `EveryDictList`.

## API

For the detailed API, see the
[Elm package site](http://package.elm-lang.org/packages/Gizra/elm-dictlist/latest),
or the links to the right, if you're already there.

## Installation

Try `elm-package install Gizra/elm-dictlist`

## Development

Try something like:

    git clone https://github.com/Gizra/elm-dictlist
    cd elm-dictlist
    npm install
    npm test
