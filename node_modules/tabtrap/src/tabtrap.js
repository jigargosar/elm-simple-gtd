/**
 * --------------------------------------------------------------------------
 * Tabtrap (v1.2.6): tabtrap.js
 * by Evan Yamanishi
 * Licensed under GPL-3.0
 * --------------------------------------------------------------------------
 */


/* CONSTANTS */

const NAME = 'tabtrap'
const VERSION = '1.2.6'
const DATA_KEY = 'tabtrap'

const KEYCODE = {
    ESCAPE: 27,
    TAB: 9
}

const Default = {
    disableOnEscape: false,
    tabbableElements: [
        'a[href]:not([tabindex="-1"])',
        'map[name] area[href]:not([tabindex="-1"])',
        'input:not([disabled]):not([tabindex="-1"])',
        'select:not([disabled]):not([tabindex="-1"])',
        'textarea:not([disabled]):not([tabindex="-1"])',
        'button:not([disabled]):not([tabindex="-1"])',
        'iframe:not([tabindex="-1"])',
        'object:not([tabindex="-1"])',
        'embed:not([tabindex="-1"])',
        '[tabindex]:not([tabindex="-1"])',
        '[contentEditable=true]:not([tabindex="-1"])'
    ]
}

const DefaultType = {
    disableOnEscape: 'boolean',
    tabbableElements: 'object'
}

const Event = {
    KEYDOWN_DISABLE: `keydown.disable.${DATA_KEY}`,
    KEYDOWN_TAB: `keydown.tab.${DATA_KEY}`
}

const jQueryAvailable = window.jQuery !== undefined

const getNodeList = (selector) => {
    switch (typeof selector) {
        case 'string':
            return document.querySelectorAll(selector)
            break
        case 'object':
            return (selector.nodeType === 1) ? selector : getNodeList(selector.selector)
            break
        default:
            throw new Error('Must provide a selector or element')
    }
}


/* CLASS DEFINITION */

class Tabtrap {

    constructor(element, config) {
        this.config = this._getConfig(element, config)
        this.element = this._assertElement(this.config.element)
        this.enabled = true
        this.tabbable = this._getTabbable()

        this._createEventListener()
        if (this.config.disableOnEscape) this._setEscapeEvent()
    }


    // getters

    static get NAME() {
        return NAME
    }

    static get VERSION() {
        return VERSION
    }

    static get DATA_KEY() {
        return DATA_KEY
    }

    static get KEYCODE() {
        return KEYCODE
    }

    static get Default() {
        return Default
    }

    static get DefaultType() {
        return DefaultType
    }

    static get Event() {
        return Event
    }

    static get jQueryAvailable() {
        return jQueryAvailable
    }


    // public

    enable() {
        this.enabled = true
    }

    disable() {
        this.enabled = false
    }

    toggle() {
        this.enabled = !this.enabled
    }


    // private

    _getConfig(element, config) {
        let _config = {}
        // check if element is actually the config object (with config.element)
        if (typeof element === 'object' && element.nodeType === undefined) {
            _config = element
        } else {
            _config.element = element
        }
        return Object.assign({},
            this.constructor.Default,
            _config
        )
    }

    _assertElement(el) {
        return (el.nodeType === 1) ? el : (typeof el === 'string') ? document.querySelector(el) : null
    }

    _getTabbable() {
        return this.element.querySelectorAll(this.config.tabbableElements.join(','))
    }

    _getKeyCode(event) {
        return event.which || event.keyCode || 0
    }

    _createEventListener() {
        if (jQueryAvailable) {
            jQuery(this.element).off(Event.KEYDOWN_TAB)
            jQuery(this.element).on(Event.KEYDOWN_TAB, (e) => this._manageFocus(e))
        } else {
            this.element.addEventListener('keydown', (e) => this._manageFocus(e))
        }
    }

    _manageFocus(e) {
        if (this._getKeyCode(e) === KEYCODE.TAB && this.enabled) {
            let tabIndex = Array.from(this.tabbable).indexOf(e.target)
            let condition = {
                outside: tabIndex < 0,
                wrapForward: tabIndex === this.tabbable.length - 1 && !e.shiftKey,
                wrapBackward: tabIndex === 0 && e.shiftKey
            }
            if (condition.outside || condition.wrapForward) {
                e.preventDefault()
                this.tabbable[0].focus()
            }
            if (condition.wrapBackward) {
                e.preventDefault()
                this.tabbable[this.tabbable.length - 1].focus()
            }
        }
    }

    _setEscapeEvent() {
        this.element.addEventListener(Event.KEYDOWN_DISABLE, (e) => {
            if (this._getKeyCode(e) === KEYCODE.ESCAPE) {
                this.disable()
            }
        })
    }


    // static

    static _jQueryInterface(config) {
        return this.each(function() {
            let data = jQuery(this).data(DATA_KEY)
            let _config = typeof config === 'object' ?
                config : null

            if (!data && /disable/.test(config)) {
                return
            }

            if (!data) {
                data = new Tabtrap(this, _config)
                jQuery(this).data(DATA_KEY, data)
            }

            if (typeof config === 'string') {
                if (data[config] === undefined) {
                    throw new Error(`No method named "${config}"`)
                }
                data[config]()
            }
        })
    }

    static trapAll(element, config) {
        let nodeList = getNodeList(element)
        let _config = (typeof config === 'object') ? config : {}
        Array.from(nodeList).forEach((node) => {
            _config.element = node
            new Tabtrap(_config)
        })
    }
}

/* JQUERY INTERFACE INITIALIZATION */

if (jQueryAvailable) {
    const JQUERY_NO_CONFLICT = jQuery.fn[NAME]
    jQuery.fn[NAME] = Tabtrap._jQueryInterface
    jQuery.fn[NAME].Constructor = Tabtrap
    jQuery.fn[NAME].noConflict = function() {
        jQuery.fn[NAME] = JQUERY_NO_CONFLICT
        return Tabtrap._jQueryInterface
    }
}

export default Tabtrap
