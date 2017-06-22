# elm-parseint
Convert String value to Int, or Int to String, with given radix.

The `parseInt` function here is similar to Javascript's parseInt(), parsing a
decimal string and returning the corresponding Int value if any. `parseIntOct`,
`parseIntHex`, and `parseIntRadix` parse strings encoded as octal, hexadecimal,
or arbitrary radix, respectively.

The `toRadix` function inverts `parseInt`, converting an Int to a String with a
given radix. `toRadix 10` is equivalent to `toString` for Int arguments.
