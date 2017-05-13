# tabtrap
Trap focus inside an object. Useful for ensuring keyboard accessibility of modal dialogs.

## Usage
Tabtrap comes with versions for two environments: a dev module version, and a standalone browser version. There are multiple ways to initialize the trap in both versions.

### tabtrap.module.js
The module version should be used in dev environments that are using import/require module patterns. It won't work as a standalone file in the browser.
```javascript
// es6
import tabtrap from 'tabtrap'
// non-es6
var tabtrap = require('tabtrap')

// initialize with the static .trapAll() method to trap multiple elements
tabtrap.trapAll('.modal')

// initialize with the class (only traps the first element found)
new tabtrap('.modal')
```

### tabtrap.browser.js
The browser version can be used directly in the browser as a standalone file. jQuery is optional.
```html
<body>
    ...
    <script src="jquery.min.js" type="text/javascript"></script>
    <script src="tabtrap.browser.js" type="text/javascript"></script>
    <script type="text/javascript">
        // initialize with jQuery
        $('.modal').tabtrap()

        // initialize without jQuery
        new tabtrap('.modal')
    </script>
</body>
```

## Options

| Option | Type | Default |
| ------ | ---- | ------- |
| `disableOnEscape` | boolean | `false` |
| `tabbableElements` | object | ([view source](blob/master/src/tabtrap.js#L23-L35)) |


## Methods

`Tabtrap.trapAll(element[, options])`
```javascript
Tabtrap.trapAll('.modal', { disableOnEscape: true })
```
You can also place the element or element selector inside the options object:

`Tabtrap.trapAll(options)`
```javascript
Tabtrap.trapAll({
    element: '.modal',
    disableOnEscape: true
})
```

**The following methods are used with jQuery**
`.tabtrap('enable')`
```javascript
$('#open').on('click', (e) => {
  $('.modal').tabtrap('enable')
})
```

`.tabtrap('disable')`
```javascript
$('#close').on('click', (e) => {
  $('.modal').tabtrap('disable');
});
```

`.tabtrap('toggle')`
```javascript
// probably don't do this.
$(document).on('keydown', function (e) {
  if (e.which === 84) {     // 't'
    $('.modal').tabtrap('toggle');
  }
});
```
