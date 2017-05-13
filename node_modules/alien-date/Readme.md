# alien-date

It's basically an English language date parser for node.js. It returns native JS Date object.

Forked Matthew Mueller's [date.js](http://matthewmueller.github.io/date/) since it took him some time to accept my PR that fixed a bug, which rendered the package completely unusable for me (it would never throw - which is supposed to do if it cannot understand the input).
Now, it would return Date instance for successfully parsed date/times and throw when it's not able to parse the input.
It's important that the API is able to tell the caller that it could not understand WTF was entered as input.  
For examples and demos, have a look at the Matthew's repo.

Fork yeah!

## Install like this

    npm install alien-date


## Examples

```js
date('10 minutes from now')
date('in 5 hours')
date('at 5pm')
date('at 12:30')
date('at 23:35')
date('in 2 days')
date('tuesday at 9am')
date('monday at 1:00am')
date('last monday at 1:00am')
date('tomorrow at 3pm')
date('yesterday at 12:30am')
date('5pm tonight')
date('tomorrow at noon')
date('next week tuesday')
date('next week tuesday at 4:30pm')
date('2 weeks from wednesday')
date('tomorrow night at 9')
date('tomorrow afternoon')
date('this morning at 9')
date('2 years from yesterday at 5pm')
date('last month')
date('tomorrow afternoon at 4:30pm 1 month from now')
date('at 12:30')
date('at 12.30')
date('tuesday at 9')
date('tomorrow at 15')
```

## API

### date(str, [offset])

Create a `Date` from a `str`. You may also supply an optional `offset` to the starting date. `offset` defaults to the current date and time.

## Tests

    npm install
    make test

## Contributors

```
project  : date
repo age : 4 months
active   : 20 days
commits  : 50
files    : 13
authors  :
  25  Matt Mueller            50.0%
  10  Bulkan Evcimen          20.0%
   9  Matthew Mueller         18.0%
   3  Eero Norri              6.0%
   2  thomas                  4.0%
   2  Marko Bonaci            4.0%
   1  Jimmy Gaussen           2.0%
```

## License

(The MIT License)

Copyright (c) 2013 Matt Mueller <mattmuelle@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
