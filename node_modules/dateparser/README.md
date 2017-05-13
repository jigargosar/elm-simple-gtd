# Date Parser

A lightweight JavaScript date library for parsing and formatting natural language relative dates.

An small example set of strings that can be parsed:

	two seconds
	1 second
	every 4 days
	every other day
	1 hour from now
	after 2 hours
	once per hour
	every 48 hours


## Using with Node

Install with npm:

```
npm install dateparser --save
```

## Using with Browser

### Bower

You can use Bower to install.

```
bower install dateparser
bower install jhaynie/dateparser
```

### JS files

If you don't use Bower as a package manager, you can copy the minified JS from `dateparser.min.js` to the location of your web assets directory and inclue it in your HTML manually.

## API

The API has only 2 methods `parse` and `format`.

### Parse

To parse a date, call `parse` with a string of text.  The result is an object with two properties: `value` (Number) and `relative` (Boolean).  The `value` property is the milliseconds value.  The `relative` property indicates if the `value` is a relative date or a recurring date.

```javascript
var result = dateparser.parse('every 1 hour');
console.log('%d', result.value);
```

If the results `relative` property is true, the value will be a date in milliseconds format from `Date.now()`. If the reuslts `relative` property is false, the value will be the absolute milliseconds value of the parsed string (for example, 1 seconds will be returned as 1000).

### Format

Format a result object returned from parse in a human readable format.

```javascript
var result = dateparser.parse('every 1 hour');
console.log(dateparser.format(result));
```

## License

Copyright (c) 2015 by Jeff Haynie. Licensed under the Apache-2.0 license.
