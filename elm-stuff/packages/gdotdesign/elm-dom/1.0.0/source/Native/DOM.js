var _gdotdesign$elm_dom$Native_DOM = function() {
  var task = _elm_lang$core$Native_Scheduler.nativeBinding
  var succeed = _elm_lang$core$Native_Scheduler.succeed
  var fail = _elm_lang$core$Native_Scheduler.fail
  var tuple0 = _elm_lang$core$Native_Utils.Tuple0

  var err = _elm_lang$core$Result$Err
  var ok = _elm_lang$core$Result$Ok

  var withElement = function(selector, method) {
    try {
      var element = document.querySelector(selector)
    } catch (error) {
      throw { ctor: "InvalidSelector", _0: selector }
    }
    if (!element) { throw { ctor: "ElementNotFound", _0: selector } }
    return method(element)
  }

  /* Get the dimensions object for an element using getBoundingClientRect. */
  var getDimensionsObject = function(selector){
    return withElement(selector, function(element){
      var rect = element.getBoundingClientRect()

      return {
        bottom: rect.bottom,
        height: rect.height,
        width: rect.width,
        right: rect.right,
        left: rect.left,
        top: rect.top
      }
    })
  }

  var async = function(method) {
    return function(){
      var args = Array.prototype.slice.call(arguments)

      return task(function(callback){
        try {
          callback(succeed(method.apply({}, args)))
        } catch (error) {
          callback(fail(error))
        }
      })
    }
  }

  var sync = function(method) {
    return function() {
      var args = Array.prototype.slice.call(arguments)

      try {
        return ok(method.apply({}, args))
      } catch (error) {
        return err(error)
      }
    }
  }

  /* ---------------------------------------------------------------------- */

  /* Runs the given message on the next animation frame. */
  var nextTick = function(){
    return task(function(callback){
      requestAnimationFrame(function(){
        callback(succeed(tuple0))
      })
    })
  }

  /* Tests if the given coordinates are over the given selector */
  var isOver = function(selector, position){
    var element = document.elementFromPoint(
      position.left - window.pageXOffset,
      position.top - window.pageYOffset
    )
    if (!element) { return err({ ctor: "ElementNotFound", _0: selector }) }
    try {
      return ok(element.matches(selector + "," + selector + " *"))
    } catch (error) {
      return err({ ctor: "InvalidSelector", _0: selector })
    }
  }

  var hasFocusedElement = function(){
    return task(function(callback){
      callback(!!document.querySelector('*:focus'))
    })
  }

  var hasFocusedElementSync = function(){
    return !!document.querySelector('*:focus')
  }

  var focus = function(selector){
    return withElement(selector, function(element){
      element.focus()
      return tuple0
    })
  }

  var blur = function(selector){
    return withElement(selector, function(element){
      element.blur()
      return tuple0
    })
  }

  var select = function(selector) {
    return withElement(selector, function(element){
      if(!element.select){
        throw { ctor: "TextNotSelectable", _0: selector }
      }
      element.select()
      return tuple0
    })
  }

  var setScrollLeft = function(position, selector){
    return withElement(selector, function(element){
      element.scrollLeft = position
      return tuple0
    })
  }

  var setScrollTop = function(position, selector){
    return withElement(selector, function(element){
      element.scrollTop = position
      return tuple0
    })
  }

  var scrollIntoView = function(selector) {
    return withElement(selector, function(element){
      element.scrollIntoView()
      return tuple0
    })
  }

  var getScrollLeft = function(selector){
    return withElement(selector, function(element){
      return element.scrollLeft
    })
  }

  var getScrollTop = function(selector){
    return withElement(selector, function(element){
      return element.scrollTop
    })
  }

  var setValue = function(value, selector){
    return withElement(selector, function(element){
      element.value = value
      return tuple0
    })
  }

  var getValue = function(selector) {
    return withElement(selector, function(element){
      return element.value || ""
    })
  }

  var windowScrollTop = function(){
    return window.pageYOffset
  }

  var windowScrollLeft = function(){
    return window.pageXOffset
  }

  var windowWidth = function(){
    return window.innerWidth
  }

  var windowHeight = function(){
    return window.innerHeight
  }

  var contains = function(selector){
    try {
      return !!document.querySelector(selector)
    } catch (error) {
      return false
    }
  }

  return {
    hasFocusedElementSync: hasFocusedElementSync,
    hasFocusedElement: hasFocusedElement,

    getDimensionsSync: sync(getDimensionsObject),
    getDimensions: async(getDimensionsObject),

    scrollIntoViewSync: sync(scrollIntoView),
    scrollIntoView: async(scrollIntoView),

    setScrollLeftSync: F2(sync(setScrollLeft)),
    setScrollLeft: F2(async(setScrollLeft)),

    setScrollTopSync: F2(sync(setScrollTop)),
    setScrollTop: F2(async(setScrollTop)),

    getScrollLeftSync: sync(getScrollLeft),
    getScrollLeft: async(getScrollLeft),

    getScrollTopSync: sync(getScrollTop),
    getScrollTop: async(getScrollTop),

    selectSync: sync(select),
    select: async(select),

    setValueSync: F2(sync(setValue)),
    setValue: F2(async(setValue)),

    getValueSync: sync(getValue),
    getValue: async(getValue),

    focusSync: sync(focus),
    focus: async(focus),

    blurSync: sync(blur),
    blur: async(blur),

    isOver: F2(isOver),
    nextTick: nextTick,
    contains: contains,

    windowScrollLeft: windowScrollLeft,
    windowScrollTop: windowScrollTop,
    windowHeight: windowHeight,
    windowWidth: windowWidth,
  }
}()
