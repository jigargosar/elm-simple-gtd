# Tuple Extra

Additional helpers for working with tuples.

For example:

```elm
foo (x, y) = (baz x, y)
```

becomes

```elm
foo = mapFirst baz
```

## Tests

You'll need `elm-test` installed. To get it

```bash
$ npm install -g elm-test
```

Then

```bash
$ elm-test
```

to run them.
