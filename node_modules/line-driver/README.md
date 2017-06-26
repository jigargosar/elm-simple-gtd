# line-driver
[![Build Status](https://travis-ci.org/bninni/line-driver.svg?branch=1.1.7)](https://travis-ci.org/bninni/line-driver)

A simple configurable module to read or write files line by line.

## Install
```
npm install line-driver
```
or
```
npm install -g line-driver
```
## Usage

Since the module usage is pretty straightforward, let's jump right into examples.

Not everything is covered in these Examples, so jump down to [API](#api) to get the full information.

First, import the module into your program:

```javascript
var LineDriver = require('line-driver');
```

For all of the examples, let's pretend that `example.txt` consists of the following:
```
1|  one
2|  two
3|  three
4|  four
5|  five
```
---
### Reading a file

**Simple Example**
```javascript
LineDriver.read( {
  in : 'path/to/example.txt',
  line : function( props, parser ){
    console.log( parser.line );
  }
} );
```

* `line` - The function to be called every time the Parser encounters a new line
  * `props` - The object that contains the Settings or Properties used by the Parser
    * The exact same `props` object is sent to every function call and can be used to share data from one function to another
    * Changing any settings in this object will not have any effect
  * `parser` - The object that allows the function to interact with the state of the Parser
    * `parser.line` - The line that the parser is currently handling
    * This object has more attributes/properties, some of which are only available in certain contexts.  Please read the [API](#api) documentation to learn more.
* `in` - The path to the file to be read (using `fs.readFile`)
    * This path can also be an web address starting with 'http://' or 'https://'


In this scenario, every line from the file will be captured and printed to the console:

```
one
two
three
four
five
>
```
---
**Line Index Exclusion**

There are five input properties that define which lines are sent to the `line` function that can be used independently from or in conjunction with each other.

* `first` - The index of the first line to capture
  * *Default :* `1`
* `last` - The index of the last line to capture
* `count` - How many total lines to capture
* `range` - An array of the [first, last] values
* `step` - Spacing betweens captured lines
  * *Default :* `1`

*Note -* There is an additional settings called `absolute`, which defines whether these indices refer to the 'absolute line index' or the 'valid line index'
  * *Default :* `false` ('valid line index')
  * [See here for examples of Absolute vs Relative](#abs_vs_valid)
  
---
* **first**

```javascript
LineDriver.read( {
  in : 'path/to/example.txt',
  line : function( props, parser ){
    console.log( parser.line );
  },
  props : {
    first : 2
  }
} );
```

Every line starting from line 2 will be captured:

```
two
three
four
five
>
```
---
* **last**

```javascript
LineDriver.read( {
  in : 'path/to/example.txt',
  line : function( props, parser ){
    console.log( parser.line );
  },
  props : {
    last : 4
  }
} );
```

Every line up to and including line 4 will be captured:

```
one
two
three
four
>
```
---
* **count**

```javascript
LineDriver.read( {
  in : 'path/to/example.txt',
  line : function( props, parser ){
    console.log( parser.line );
  },
  props : {
    first : 2,
    count : 3
  }
} );
```

Only 3 lines will be captured, starting from line 2:

```
two
three
four
>
```
---
* **range**

```javascript
LineDriver.read( {
  in : 'path/to/example.txt',
  line : function( props, parser ){
    console.log( parser.line );
  },
  props : {
    range : [2,4]
  }
} );
```

Only lines 2-4 will be captured:

```
two
three
four
>
```

You can also use an array of ranges:

```javascript
LineDriver.read( {
  in : 'path/to/example.txt',
  line : function( props, parser ){
    console.log( parser.line );
  },
  props : {
    range : [[1,3],[3,5]]
  }
} );
```

The ranges are processed sequentially:

```
one
two
three
three
four
five
>
```

*Note -* `init` and `close` is still only run once
---
* **step**

```javascript
LineDriver.read( {
  in : 'path/to/example.txt',
  line : function( props, parser ){
    console.log( parser.line );
  },
  props : {
    step : 2
  }
} );
```

Every other line will be captured:

```
one
three
five
>
```
---
**String Exclusion**

There are two input functions that can access `parser.line` before it gets sent to the `line` function.

* `valid` - The function to determine if the `parser.line` is valid or not.
  * *Note -* An invalid line will not be sent to the `line` function 
* `clean` - The function to modify the `parser.line` **_before_** sending for validation

---
**valid**

```javascript
LineDriver.read( {
  in : 'path/to/example.txt',
  line : function( props, parser ){
    console.log( parser.line );
  },
  valid : function( props, parser ){
    parser.valid = parser.line.length > 3;
  }
} );
```

* `parser.valid` - Determines whether the current line is a valid line or not.

*Note -* `parser.line` in this context is only a copy.  Modifying it will have no effect.


Only lines where the the `parser.line` is longer than three characters will be captured:

```
three
four
five
>
```
---
**clean**

```javascript
LineDriver.read( {
  in : 'path/to/example.txt',
  line : function( props, parser ){
    console.log( parser.line );
  },
  clean : function( props, parser ){
    parser.line = parser.line.slice(1);
  },
  valid : function( props, parser ){
    parser.valid = parser.line.length > 3;
  }
} );
```

Only lines where the the `clean`-ed `parser.line` is longer than three characters will be captured:

```
hree
>
```
---
There are also three input properties that can allow for automatic cleaning and validation of `parser.line`

* `commentDelim` - The character which indicates the start of a comment
  * *Default :* `''`
* `trim` - Whether or not surrounding whitespace should be removed from the string
  * *Default :* `false`
* `ignoreEmpty` - Whether or not empty strings (`''`) should be be considered invalid
  * *Default :* `false`

In the following example, let's assume that that `example.txt` now looks like the following:
```
1|  one
2|
3|  two    #comment?
4|    three
5|  four
6|  #another comment:
7|  five
```

Now let's use the above properties:
```javascript
LineDriver.read( {
  in : 'path/to/example.txt',
  line : function( props, parser ){
    console.log( parser.line );
  },
  props : {
    commentDelim : '#',
    trim : true,
    ignoreEmpty : true
  }
} );
```

What happens behind the scenes?

First, before any `clean`-ing occurs, the parser does equivalent of the following:
```javascript
if( props.commentDelim ) parser.line = parser.line.split( props.commentDelim )[0];
if( props.trim ) parser.line.trim();
```

Then, before any `valid`-ation occurs, the parser does equivalent of the following:
```javascript
if( props.ignoreEmpty && !parser.line ) parser.valid = false;
```

And finally, our captured lines look like this:

```
one
two
three
four
five
>
```

---
**Absolute vs Valid Lines**<a name='abs_vs_valid'></a>

There are two methods of excluding lines based on the index, using the absolute line index or using the valid line index.
* Denoted by the `absolute` property

Below are examples of different properties (using the same messy file and line validation as above) and what they will produce:


Using `first`:

---
```javascript
props : {
  first : 3,
  absolute : true
}
```

Every line starting from line 3 will be checked for validation

```
two
three
four
five
>
```
---
Using `last`:

```javascript
props : {
  last : 3,
  absolute : true
}
```

Every line up to and including line 3 will be checked for validation

```
one
two
>
```
---
Using `step`:

```javascript
props : {
  step : 2,
  absolute : true
}
```

Every other line will be checked for validation:

```
one
two
four
five
>
```

---
**Closing a File**

A Parser can be forced to close by running the `parser.close()` function.  

```javascript
LineDriver.read( {
  in : 'path/to/example.txt',
  line : function( props, parser ){
    console.log( parser.line );
    if( parser.line === 'three' ) parser.close();
  }
} );
```

* `parser.close` - The function to stop parsing lines and call the `close` and `write` functions (if applicable)

Every line will be captured until the `parser.close()` function is called

```
one
two
three
>
```

Running this will stop all line parsing, and call the input `close` function (and write the `out` file, if applicable).

---
**Other Functions**

There are three more input functions:
* `init` - The function to run once the `in` file is loaded but before the file parsing begins
* `close` - The function to run once the `in` file is done being parsed
* `write` - The function to run once the `out` file has been written
  * *Note -* This is only used by `LineDriver.write`

Let's again assume that `example.txt` is back to its original state.

```javascript
LineDriver.read( {
  in : 'path/to/example.txt',
  init : function( props, parser ){
    console.log('Parsing Started...');
  },
  line : function( props, parser ){
    console.log( '\t' + parser.line );
  },
  close : function( props, parser ){
    console.log('...Parsing Finished');
  }
} );
```

And the console will look like this:

```
Parsing Started...
  one
  two
  three
  four
  five
...Parsing Finished
>
```
---
**Other Properties**

There are five more input properties:
* `sync` - Whether or not to use `fs.readFileSync` & `fs.writeFileSync` instead of `fs.readFile` & `fs.writeFile`
  * *Default :* `false`
* `encoding` - The encoding of the `in` and `out` files
  * *Default :* `'utf8'`
* `delimiter` - The String or RegExp to apply to split the `in` file into an array of lines.
  * *Default :* `new RegExp('\r\n?|\r?\n')`
* `join` - The String to use to join every line in the `out` file before writing.
  * *Default :* `'\n'`
* `eof` - The String to add to the end of the file (attached to the last line)
  * *Default :* `''`
  
---
### Writing a file

**Example**
```javascript
LineDriver.write( {
  in : 'path/to/example.txt',
  out : 'path/to/new/file.txt',
  line : function( props, parser ){
    parser.write( parser.line );
  }
} );
```

The only difference between reading and writing a file is the `out` property and the `parser.write` function.

* `out` - The path to the file to be written (using `fs.writeFile`)
  * *Optional* - If no `out` path is given, it write back to the `in` path
* `parser.write` - The function to add a line to the `out` file.  Input can be a string or array of strings
  * *Note -* `parser.write` still exists for `LineDriver.read()`, but it will not do anything.

 
## Settings

Every `props` attribute listed above (except `in`, `out`, `last` and `count`) have a default value associated with them.  These default values can be changed.

Let's assume that our program will only be parsing files that look like this:

```
1|    one  :  1  ,  two  :  2  ,  three  :  3  ,  four  :  4  ,  five  :  5  
```

If we only wanted to capture the keys from these files, then the default settings can be updated as follows:

```javascript
LineDriver.settings( {
  commentDelim : ':',
  trim : true,
  ignoreEmpty : true,
  delimiter : ','
} );
```
---
## Templates

Read about Templates in the API section, [here](#templates_api)
--- 
## API<a name="api"></a>
---
### Settings<a name="settings_api"></a>

The `LineDriver` module has default settings associated with it.  These default settings can be updated to your preference.

```javascript
LineDriver.settings( { opts } )
```

The input options are `key : value` pairs where:
* `key` - The name of the setting to update
* `value` - The value to set as default

The default settings and values are:

* `commentDelim` - The character which indicates the start of a comment
  * *Default :* `''`
* `delimiter` - The String or RegExp to apply to split the `in` file into an array of lines.
  * *Default :* `new RegExp('\r\n?|\r?\n')`
* `encoding` - The encoding of the `in` and `out` files
  * *Default :* `'utf8'`
* `eof` - The String to add to the end of the file (attached to the last line)
  * *Default :* `''`
* `absolute` - Whether the **Line Index Exclusion** calculations use the 'absolute line index' or the 'valid line index'
  * *Default :* `false`
* `first` - The index of the first line to capture
  * *Default :* `1`
* `ignoreEmpty` - Whether or not empty strings (`''`) should be be considered invalid
  * *Default :* `false`
* `join` - The String to use to join every line in the `out` file before writing.
  * *Default :* `'\n'`
* `step` - Spacing betweens captured lines
  * *Default :* `1`
* `sync` - Whether or not to use `fs.readFileSync` & `fs.writeFileSync` instead of `fs.readFile` & `fs.writeFile`
  * *Default :* `false`
* `trim` - Whether or not surrounding whitespace should be removed from the string
  * *Default :* `false`
* `maxRedirects` - The number of redirects (when reading from an http/https source) before failing
  * *Default :* `5`

---
  
### Reading and Writing

The LineDriver module can read or write a file using the following:
```javascript
LineDriver.read( { opts } )
```
or
```javascript
LineDriver.write( { opts } )
```

The input options are one or more of the following:
* **Properties**
* **Functions**
* **Templates**
* **Paths**

Here is a simple example:

In this example:
* `line` is one of the possible input **Functions**
* `props` is the input **Properties** object

```javascript
LineDriver.read( {
  in : 'path/to/example.txt',
  line : function( props, parser ){
    console.log( parser.line );
  }
} );
```
---
**Paths**

There are two different path objects that the parser recognizes:

* `in` - The path to the file to be read (using `fs.readFile`)
  * **_Required_**
  * This path can also be an web address starting with 'http://' or 'https://'
* `out` - The path to the file to be written (using `fs.writeFile`)
  * *Optional* - default = `in` path
  * This is only used by `LineDriver.write`
  
*Note -* The number of acceptable redirects can be set using the `maxRedirects` property (see above)
  
---
**Functions**

There are six functions that the Parser recognizes and handles:

* `init` - The function to run once the `in` file is loaded but before the file parsing begins
* `clean` - The function to modify the `parser.line` **_before_** sending for validation
* `valid` - The function to determine if the `parser.line` is valid or not.
  * An invalid line will not be sent to the `line` function 
* `line` - The function to be called every time the Parser encounters a new line
* `close` - The function to run once the `in` file is done being parsed
* `write` - The function to run once the `out` file has been written
  * This is only used by `LineDriver.write`

Every function has two inputs to it:

* `props` - The object that contains the Settings/Properties used by the Parser
  * It also includes any additional data that was stored in the input **Properties** object
  * The exact same `props` object is sent to every function call and can be used to share data from one function to another
  * Changing any settings in this object will not have any effect
* `parser` -The object that allows the function to interact with the state of the Parser
  * Some `parser` properties are only available in certain contexts. (See below)
  
---
* **init**

The parser object has the following attributes:

* `write` - The function to add a line to the out file.  Input can be a string or array of strings
  * This is only used by `LineDriver.write`

```javascript
  init : function( props, parser ){
    console.log('Began parsing the file.');
    parser.write('Start of File');
  }
```
---
* **clean**

The parser object has the following attributes:
* `line` - The line that the parser is currently handling
* `index` - The object containing the index of the current line
  * `absolute` - The index of the current line from the start of the file, including invalid lines
  * `valid` - The index of the **_previous_** valid line from the first valid line, excluding invalid lines

```javascript
  clean : function( props, parser ){
    //to make sure every line is lowercase
    parser.line = parser.line.toLowerCase();
  }
```
---
* **valid**

The parser object has the following attributes:
* `line` - The line that the parser is currently handling
* `valid` - Determines whether the current line is a valid line or not.
* `index` - The object containing the index of the current line
  * `absolute` - The index of the current line from the start of the file, including invalid lines
  * `valid` - The index of the **_previous_** valid line from the first valid line, excluding invalid lines

*Notes:*
  * In this context, `line` is a copy of the actual `line`; modifying it will have no effect
  * An invalid line will not be sent to the `line` function

```javascript
  valid : function( props, parser ){
    //to ignore lines that are three characters or less
    parser.valid = parser.line.length > 3;
  }
```
---
* **line**

The parser object has the following attributes:
* `line` - The line that the parser is currently handling
* `index` - The object containing the index of the current line
  * `absolute` - The index of the current line from the start of the file, including invalid lines
  * `valid` - The index of the **_current__** line from the first valid line, excluding invalid lines
* `close` - The function to stop parsing lines and call the `close` and `write` functions (if applicable)
* `hasNextLine` - The function to see if there are any valid lines left in the file
  * Arguments:
    * `count` - Number of valid lines to check for
      * *Optional,* default = `step` Property
* `goToLine` - The function to capture the next valid line
  * Arguments:
    1. `count` - Spacing between current line and desired line
      * *Optional,* default = `step` Property
    2. `ignoreValid` - Should the desired line not increase the valid line index?
      * *Optional,* default = `false`
* `nextLine` - The next line in the file
  * Invoking this will update the `line` and `index` values to represent the next line
  * Since this internally updates the current line, the parser will not send that line to the `line` function on the next pass
* `write` - The function to add a line to the out file.  Input can be a string or array of strings
  * This is only used by `LineDriver.write`

```javascript
  line : function( props, parser ){
    console.log('Line : ' + parser.line);
    
    if( parser.hasNextLine() ){
      console.log('Next Line : ' + parser.nextLine);
      //parser.line has been updated to the new line since we accessed parser.nextLine
      console.log('Line -> Next Line : ' + parser.line);
    }
    
    if( parser.line === 'thats all folks' ) parser.close();
  }
```
---
* **close**

The parser object has the following attributes:
* `write` - The function to add a line to the out file.  Input can be a string or array of strings
  * This is only used by `LineDriver.write`

```javascript
  close : function( props, parser ){
    console.log('Done parsing the file.');
    parser.write('End of file');
  }
```
---
* **write**
```javascript
  write : function( props, parser ){
    console.log('Done writing the file.');
  }
```
---
**Properties**

The properties are any settings which you would like to override the default value of.

In additional to the settings listed [above](#settings_api), the Parser can recognize these additional settings:

* `last` - The index of the last line to capture
* `count` - How many total lines to capture
  
*Note -* Any additional data can be attached to the properties object and can be shared 

---
**Templates** <a name='templates_api'></a>

Templates can be used to create default values for properties or functions.

Let's create a template for parsing `.csv` files and assume that `example.txt` looks like the following:
```
1|  ,X,Y
2|  X,XX,XY
3|  X,XX,XY
```

Let's assume we want to create a template that parses the above table, and then only sends the 'cells' to the `line` function

```javascript
LineDriver.template('table', {
  //use the props object to store data
  init : function( next, props, parser ){
    props.table = [];
    props.titles = {
      rows : [],
      cols : []
    };
    next();
  },
  line : function( next, props, parser ){
    //turn the row into an array of cells
    var rowTitle,
      row = parser.line.split(',');
    
    //the first cell contains the row title
    rowTitle = row.splice(0,1)[0];
    
    //the first row contains the column titles
    if( parser.index.valid === 1 ) props.titles.cols = row;
    else{
      props.titles.rows.push( rowTitle );
      //send each cell to the line function
      row.forEach(function( value, i ){
        props.currentCell = {
          value : value,
          col : i,
          row : parser.index.valid - 1
        };
        next();
      });
    }
  }
} );
```

* `next` - The function to call the corresponding function from the original input
  * *i.e. :* Running `next()` in the `line` function will called the input `line` function
* `parser.index` - The object containing the index of the current line
  * `absolute` - The index of the current line from the start of the file, including invalid lines
  * `valid` - The index of the current line from the first valid line, excluding invalid lines

Now let's use that template:
  
```javascript
LineDriver.read({
  in : 'path/to/example.txt',
  line : function(args, parser){
    var value = props.currentCell.value,
      colTitle = props.titles.cols[props.currentCell.row],
      rowTitle = props.titles.rows[props.currentCell.col];
      
    console.log( rowTitle + ' + ' + colTitle + ' = ' + value );
  },
  template : ['table']
})
```

* `template` - An array of names of templates to use when parsing the `in` file.
  * *Note -* If more than one template name exists, the `next()` function will called the corresponding function in the next template in the list
  * The first template called is index 0
    * Once no more templates exist, then the corresponding input function will be called

Running the above function and template will produce a console that looks like the following:
```
X + X = XX
X + Y = XY
X + X = XX
X + Y = XY
>
```

Useful for genetics, not for algebra.

*Note -* The 'default' template, if it exists, will be automatically applied as the first template **_unless_** it already appears in the input `template` list.

Templates give you some freedom on how data gets sent to the final function.  For example, the above `row.forEach()` function can look like the following:
```javascript
//send each cell to the line function
row.forEach(function( value, i ){
  props.handleCell(value, props.titles.cols[i], rowTitle);
});
```

And it can be used in the following manner:
 
```javascript
LineDriver.read({
  in : 'path/to/example.txt',
  props : {
    handleCell : function(value, colTitle, rowTitle){
      console.log( rowTitle + ' + ' + colTitle + ' = ' + value );
    }
  },
  template : ['table']
})
```

## License
### MIT