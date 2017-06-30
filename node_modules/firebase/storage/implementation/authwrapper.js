/*! @license Firebase v4.1.3
Build: rev-1234895
Terms: https://firebase.google.com/terms/ */

'use strict';

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.AuthWrapper = undefined;

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _constants = require('./constants');

var constants = _interopRequireWildcard(_constants);

var _error2 = require('./error');

var errorsExports = _interopRequireWildcard(_error2);

var _failrequest = require('./failrequest');

var _location = require('./location');

var _promise_external = require('./promise_external');

var promiseimpl = _interopRequireWildcard(_promise_external);

var _requestmap = require('./requestmap');

var _type = require('./type');

var type = _interopRequireWildcard(_type);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

/**
 * @param app If null, getAuthToken always resolves with null.
 * @param service The storage service associated with this auth wrapper.
 *     Untyped to avoid circular type dependencies.
 * @struct
 */
var AuthWrapper = exports.AuthWrapper = function () {
    function AuthWrapper(app, maker, requestMaker, service, pool) {
        _classCallCheck(this, AuthWrapper);

        this.bucket_ = null;
        this.deleted_ = false;
        this.app_ = app;
        if (this.app_ !== null) {
            var options = this.app_.options;
            if (type.isDef(options)) {
                this.bucket_ = AuthWrapper.extractBucket_(options);
            }
        }
        this.storageRefMaker_ = maker;
        this.requestMaker_ = requestMaker;
        this.pool_ = pool;
        this.service_ = service;
        this.maxOperationRetryTime_ = constants.defaultMaxOperationRetryTime;
        this.maxUploadRetryTime_ = constants.defaultMaxUploadRetryTime;
        this.requestMap_ = new _requestmap.RequestMap();
    }

    _createClass(AuthWrapper, [{
        key: 'getAuthToken',
        value: function getAuthToken() {
            // TODO(andysoto): remove ifDef checks after firebase-app implements stubs
            // (b/28673818).
            if (this.app_ !== null && type.isDef(this.app_.INTERNAL) && type.isDef(this.app_.INTERNAL.getToken)) {
                return this.app_.INTERNAL.getToken().then(function (response) {
                    if (response !== null) {
                        return response.accessToken;
                    } else {
                        return null;
                    }
                }, function () {
                    return null;
                });
            } else {
                return promiseimpl.resolve(null);
            }
        }
    }, {
        key: 'bucket',
        value: function bucket() {
            if (this.deleted_) {
                throw errorsExports.appDeleted();
            } else {
                return this.bucket_;
            }
        }
        /**
         * The service associated with this auth wrapper. Untyped to avoid circular
         * type dependencies.
         */

    }, {
        key: 'service',
        value: function service() {
            return this.service_;
        }
        /**
         * Returns a new firebaseStorage.Reference object referencing this AuthWrapper
         * at the given Location.
         * @param loc The Location.
         * @return Actually a firebaseStorage.Reference, typing not allowed
         *     because of circular dependency problems.
         */

    }, {
        key: 'makeStorageReference',
        value: function makeStorageReference(loc) {
            return this.storageRefMaker_(this, loc);
        }
    }, {
        key: 'makeRequest',
        value: function makeRequest(requestInfo, authToken) {
            if (!this.deleted_) {
                var request = this.requestMaker_(requestInfo, authToken, this.pool_);
                this.requestMap_.addRequest(request);
                return request;
            } else {
                return new _failrequest.FailRequest(errorsExports.appDeleted());
            }
        }
        /**
         * Stop running requests and prevent more from being created.
         */

    }, {
        key: 'deleteApp',
        value: function deleteApp() {
            this.deleted_ = true;
            this.app_ = null;
            this.requestMap_.clear();
        }
    }, {
        key: 'maxUploadRetryTime',
        value: function maxUploadRetryTime() {
            return this.maxUploadRetryTime_;
        }
    }, {
        key: 'setMaxUploadRetryTime',
        value: function setMaxUploadRetryTime(time) {
            this.maxUploadRetryTime_ = time;
        }
    }, {
        key: 'maxOperationRetryTime',
        value: function maxOperationRetryTime() {
            return this.maxOperationRetryTime_;
        }
    }, {
        key: 'setMaxOperationRetryTime',
        value: function setMaxOperationRetryTime(time) {
            this.maxOperationRetryTime_ = time;
        }
    }], [{
        key: 'extractBucket_',
        value: function extractBucket_(config) {
            var bucketString = config[constants.configOption] || null;
            if (bucketString == null) {
                return null;
            }
            var loc = _location.Location.makeFromBucketSpec(bucketString);
            return loc.bucket;
        }
    }]);

    return AuthWrapper;
}();
//# sourceMappingURL=authwrapper.js.map
