/*! @license Firebase v4.1.3
Build: rev-1234895
Terms: https://firebase.google.com/terms/ */

'use strict';

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.FailRequest = undefined;

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _promise_external = require('./promise_external');

var promiseimpl = _interopRequireWildcard(_promise_external);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

/**
 * A request whose promise always fails.
 * @struct
 * @template T
 */
var FailRequest = exports.FailRequest = function () {
    function FailRequest(error) {
        _classCallCheck(this, FailRequest);

        this.promise_ = promiseimpl.reject(error);
    }
    /** @inheritDoc */


    _createClass(FailRequest, [{
        key: 'getPromise',
        value: function getPromise() {
            return this.promise_;
        }
        /** @inheritDoc */

    }, {
        key: 'cancel',
        value: function cancel() {
            arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : false;
        }
    }]);

    return FailRequest;
}();
//# sourceMappingURL=failrequest.js.map
