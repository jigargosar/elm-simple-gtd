# elm-dom
[![Build Status](https://travis-ci.org/gdotdesign/elm-dom.svg?branch=master)](https://travis-ci.org/gdotdesign/elm-dom)
![Elm Package Version](https://img.shields.io/badge/elm%20package-0.1.6-brightgreen.svg)

Alternative Elm package for DOM manipulation.

## Why? What's wrong with Elms DOM package?
The official DOM package have a different mindset and some missing features (check the comparison below).

This package aims to have a similar API that JavaScript developers are used to, but in a more structured way.

These APIs include:

- [document.elementFromPoint()](https://developer.mozilla.org/en-US/docs/Web/API/Document/elementFromPoint) to test if an element is over a point (usually the cursor)
- [Element.getBoundingClientRect()](https://developer.mozilla.org/en/docs/Web/API/Element/getBoundingClientRect) to get dimensions
- [Element.select()](https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement/select) to select text in inputs and textareas
- [Element.focus()](https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/focus) to focus elements
- [Element.blur()](https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/blur) to blur elements

Without some of these APIs is really difficult to create some UI interactions (dropdowns, drag & drop, etc..), and developers
are forced to use unusal methods to replace these (maily abusing decoders as seen in [debois/elm-dom](https://github.com/debois/elm-dom)) which is not ideal.

## Synchronous and Asynchronous APIs
This package provides synchronous and asynchronous versions of the APIs to provide even more flexibility:

Asynchronous functions are the default and they give back a `Task` to execute:
```elm
DOM.getDimensions "some selector"
-- Task DOM.Error DOM.Dimensions
```

Synchronous functions are executed at runtime and give back a `Result`:
```elm
DOM.getDimensions "some selector"
-- Result DOM.Error DOM.Dimensions
```

They are identical in every way, just they give back the data in a different
format.

## API
```elm
-- DOM
idSelector : String -> Selector
contains : String -> Bool
isOver : String -> Position -> Result Error Bool
focus : Selector -> Task Error ()
focusSync : Selector -> Result Error ()
blur : Selector -> Task Error ()
blurSync : Selector -> Result Error ()
hasFocusedElement : Task Never Bool
hasFocusedElementSync : () -> Bool
select : Selector -> Task Error ()
selectSync : Selector -> Result Error ()
getDimensions : Selector -> Task Error Dimensions
getDimensionsSync : Selector -> Result Error Dimensions
setScrollLeft : Int -> Selector -> Task Error ()
setScrollLeftSync : Int -> Selector -> Result Error ()
setScrollTop : Int -> Selector -> Task Error ()
setScrollTopSync : Int -> Selector -> Result Error ()
scrollIntoView : Selector -> Task Error ()
scrollIntoViewSync : Selector -> Result Error ()
getScrollLeft : Selector -> Task Error Int
getScrollLeftSync : Selector -> Result Error Int
getScrollTop : Selector -> Task Error Int
getScrollTopSync : Selector -> Result Error Int
setValue : String -> Selector -> Task Error ()
setValueSync : String -> Selector -> Result Error ()
getValue : Selector -> Task Error String
getValueSync : Selector -> Result Error String

-- DOM.Window
scrollTop : () -> Float
scrollLeft : () -> Float
width : () -> Float
height : () -> Float
```

## Missing APIs
If you miss some of the APIs just open an issue or leave a comment on
[this issue](https://github.com/gdotdesign/elm-dom/issues/1).

## DOM Packages Comparison
Here you can find the features of each DOM related package.

Feature                                       | gdotdesign/elm-dom | elm-lang/dom | debois/elm-dom
----------------------------------------------|--------------------|--------------|---------------
focus                                         | x                  | x            |
blur                                          | x                  | x            |
set horizontal scroll position                | x                  | x            |
get horizontal scroll position                | x                  | x            | x
set vertical scroll position                  | x                  | x            |
get vertical scroll position                  | x                  | x            | x
scroll an element into the viewport           | x                  |              |
get dimensions of an element                  | x                  |              | x
set value of an element                       | x                  |              |
get value of an element                       | x                  |              |
select all text in an input / textarea        | x                  |              |
test if an element is over the given position | x                  |              |
test if is there any focused element          | x                  |              |
