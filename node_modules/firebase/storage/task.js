/*! @license Firebase v4.1.3
Build: rev-1234895
Terms: https://firebase.google.com/terms/ */

'use strict';

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.UploadTask = undefined;

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }(); /**
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     * Copyright 2017 Google Inc.
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     *
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     * Licensed under the Apache License, Version 2.0 (the "License");
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     * you may not use this file except in compliance with the License.
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     * You may obtain a copy of the License at
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     *
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     *   http://www.apache.org/licenses/LICENSE-2.0
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     *
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     * Unless required by applicable law or agreed to in writing, software
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     * distributed under the License is distributed on an "AS IS" BASIS,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     * See the License for the specific language governing permissions and
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     * limitations under the License.
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     */
/**
 * @fileoverview Defines types for interacting with blob transfer tasks.
 */


var _taskenums = require('./implementation/taskenums');

var fbsTaskEnums = _interopRequireWildcard(_taskenums);

var _observer = require('./implementation/observer');

var _tasksnapshot = require('./tasksnapshot');

var _args = require('./implementation/args');

var fbsArgs = _interopRequireWildcard(_args);

var _array = require('./implementation/array');

var fbsArray = _interopRequireWildcard(_array);

var _async = require('./implementation/async');

var _error = require('./implementation/error');

var errors = _interopRequireWildcard(_error);

var _promise_external = require('./implementation/promise_external');

var fbsPromiseimpl = _interopRequireWildcard(_promise_external);

var _requests = require('./implementation/requests');

var fbsRequests = _interopRequireWildcard(_requests);

var _type = require('./implementation/type');

var typeUtils = _interopRequireWildcard(_type);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

/**
 * Represents a blob being uploaded. Can be used to pause/resume/cancel the
 * upload and manage callbacks for various events.
 */
var UploadTask = exports.UploadTask = function () {
    /**
     * @param ref The firebaseStorage.Reference object this task came
     *     from, untyped to avoid cyclic dependencies.
     * @param blob The blob to upload.
     */
    function UploadTask(ref, authWrapper, location, mappings, blob) {
        var _this = this;

        var metadata = arguments.length > 5 && arguments[5] !== undefined ? arguments[5] : null;

        _classCallCheck(this, UploadTask);

        this.transferred_ = 0;
        this.needToFetchStatus_ = false;
        this.needToFetchMetadata_ = false;
        this.observers_ = [];
        this.error_ = null;
        this.uploadUrl_ = null;
        this.request_ = null;
        this.chunkMultiplier_ = 1;
        this.resolve_ = null;
        this.reject_ = null;
        this.ref_ = ref;
        this.authWrapper_ = authWrapper;
        this.location_ = location;
        this.blob_ = blob;
        this.metadata_ = metadata;
        this.mappings_ = mappings;
        this.resumable_ = this.shouldDoResumable_(this.blob_);
        this.state_ = _taskenums.InternalTaskState.RUNNING;
        this.errorHandler_ = function (error) {
            _this.request_ = null;
            _this.chunkMultiplier_ = 1;
            if (error.codeEquals(errors.Code.CANCELED)) {
                _this.needToFetchStatus_ = true;
                _this.completeTransitions_();
            } else {
                _this.error_ = error;
                _this.transition_(_taskenums.InternalTaskState.ERROR);
            }
        };
        this.metadataErrorHandler_ = function (error) {
            _this.request_ = null;
            if (error.codeEquals(errors.Code.CANCELED)) {
                _this.completeTransitions_();
            } else {
                _this.error_ = error;
                _this.transition_(_taskenums.InternalTaskState.ERROR);
            }
        };
        this.promise_ = fbsPromiseimpl.make(function (resolve, reject) {
            _this.resolve_ = resolve;
            _this.reject_ = reject;
            _this.start_();
        });
        // Prevent uncaught rejections on the internal promise from bubbling out
        // to the top level with a dummy handler.
        this.promise_.then(null, function () {});
    }

    _createClass(UploadTask, [{
        key: 'makeProgressCallback_',
        value: function makeProgressCallback_() {
            var _this2 = this;

            var sizeBefore = this.transferred_;
            return function (loaded) {
                _this2.updateProgress_(sizeBefore + loaded);
            };
        }
    }, {
        key: 'shouldDoResumable_',
        value: function shouldDoResumable_(blob) {
            return blob.size() > 256 * 1024;
        }
    }, {
        key: 'start_',
        value: function start_() {
            if (this.state_ !== _taskenums.InternalTaskState.RUNNING) {
                // This can happen if someone pauses us in a resume callback, for example.
                return;
            }
            if (this.request_ !== null) {
                return;
            }
            if (this.resumable_) {
                if (this.uploadUrl_ === null) {
                    this.createResumable_();
                } else {
                    if (this.needToFetchStatus_) {
                        this.fetchStatus_();
                    } else {
                        if (this.needToFetchMetadata_) {
                            // Happens if we miss the metadata on upload completion.
                            this.fetchMetadata_();
                        } else {
                            this.continueUpload_();
                        }
                    }
                }
            } else {
                this.oneShotUpload_();
            }
        }
    }, {
        key: 'resolveToken_',
        value: function resolveToken_(callback) {
            var _this3 = this;

            this.authWrapper_.getAuthToken().then(function (authToken) {
                switch (_this3.state_) {
                    case _taskenums.InternalTaskState.RUNNING:
                        callback(authToken);
                        break;
                    case _taskenums.InternalTaskState.CANCELING:
                        _this3.transition_(_taskenums.InternalTaskState.CANCELED);
                        break;
                    case _taskenums.InternalTaskState.PAUSING:
                        _this3.transition_(_taskenums.InternalTaskState.PAUSED);
                        break;
                    default:
                }
            });
        }
        // TODO(andysoto): assert false

    }, {
        key: 'createResumable_',
        value: function createResumable_() {
            var _this4 = this;

            this.resolveToken_(function (authToken) {
                var requestInfo = fbsRequests.createResumableUpload(_this4.authWrapper_, _this4.location_, _this4.mappings_, _this4.blob_, _this4.metadata_);
                var createRequest = _this4.authWrapper_.makeRequest(requestInfo, authToken);
                _this4.request_ = createRequest;
                createRequest.getPromise().then(function (url) {
                    _this4.request_ = null;
                    _this4.uploadUrl_ = url;
                    _this4.needToFetchStatus_ = false;
                    _this4.completeTransitions_();
                }, _this4.errorHandler_);
            });
        }
    }, {
        key: 'fetchStatus_',
        value: function fetchStatus_() {
            var _this5 = this;

            // TODO(andysoto): assert(this.uploadUrl_ !== null);
            var url = this.uploadUrl_;
            this.resolveToken_(function (authToken) {
                var requestInfo = fbsRequests.getResumableUploadStatus(_this5.authWrapper_, _this5.location_, url, _this5.blob_);
                var statusRequest = _this5.authWrapper_.makeRequest(requestInfo, authToken);
                _this5.request_ = statusRequest;
                statusRequest.getPromise().then(function (status) {
                    status = status;
                    _this5.request_ = null;
                    _this5.updateProgress_(status.current);
                    _this5.needToFetchStatus_ = false;
                    if (status.finalized) {
                        _this5.needToFetchMetadata_ = true;
                    }
                    _this5.completeTransitions_();
                }, _this5.errorHandler_);
            });
        }
    }, {
        key: 'continueUpload_',
        value: function continueUpload_() {
            var _this6 = this;

            var chunkSize = fbsRequests.resumableUploadChunkSize * this.chunkMultiplier_;
            var status = new fbsRequests.ResumableUploadStatus(this.transferred_, this.blob_.size());
            // TODO(andysoto): assert(this.uploadUrl_ !== null);
            var url = this.uploadUrl_;
            this.resolveToken_(function (authToken) {
                var requestInfo = void 0;
                try {
                    requestInfo = fbsRequests.continueResumableUpload(_this6.location_, _this6.authWrapper_, url, _this6.blob_, chunkSize, _this6.mappings_, status, _this6.makeProgressCallback_());
                } catch (e) {
                    _this6.error_ = e;
                    _this6.transition_(_taskenums.InternalTaskState.ERROR);
                    return;
                }
                var uploadRequest = _this6.authWrapper_.makeRequest(requestInfo, authToken);
                _this6.request_ = uploadRequest;
                uploadRequest.getPromise().then(function (newStatus) {
                    _this6.increaseMultiplier_();
                    _this6.request_ = null;
                    _this6.updateProgress_(newStatus.current);
                    if (newStatus.finalized) {
                        _this6.metadata_ = newStatus.metadata;
                        _this6.transition_(_taskenums.InternalTaskState.SUCCESS);
                    } else {
                        _this6.completeTransitions_();
                    }
                }, _this6.errorHandler_);
            });
        }
    }, {
        key: 'increaseMultiplier_',
        value: function increaseMultiplier_() {
            var currentSize = fbsRequests.resumableUploadChunkSize * this.chunkMultiplier_;
            // Max chunk size is 32M.
            if (currentSize < 32 * 1024 * 1024) {
                this.chunkMultiplier_ *= 2;
            }
        }
    }, {
        key: 'fetchMetadata_',
        value: function fetchMetadata_() {
            var _this7 = this;

            this.resolveToken_(function (authToken) {
                var requestInfo = fbsRequests.getMetadata(_this7.authWrapper_, _this7.location_, _this7.mappings_);
                var metadataRequest = _this7.authWrapper_.makeRequest(requestInfo, authToken);
                _this7.request_ = metadataRequest;
                metadataRequest.getPromise().then(function (metadata) {
                    _this7.request_ = null;
                    _this7.metadata_ = metadata;
                    _this7.transition_(_taskenums.InternalTaskState.SUCCESS);
                }, _this7.metadataErrorHandler_);
            });
        }
    }, {
        key: 'oneShotUpload_',
        value: function oneShotUpload_() {
            var _this8 = this;

            this.resolveToken_(function (authToken) {
                var requestInfo = fbsRequests.multipartUpload(_this8.authWrapper_, _this8.location_, _this8.mappings_, _this8.blob_, _this8.metadata_);
                var multipartRequest = _this8.authWrapper_.makeRequest(requestInfo, authToken);
                _this8.request_ = multipartRequest;
                multipartRequest.getPromise().then(function (metadata) {
                    _this8.request_ = null;
                    _this8.metadata_ = metadata;
                    _this8.updateProgress_(_this8.blob_.size());
                    _this8.transition_(_taskenums.InternalTaskState.SUCCESS);
                }, _this8.errorHandler_);
            });
        }
    }, {
        key: 'updateProgress_',
        value: function updateProgress_(transferred) {
            var old = this.transferred_;
            this.transferred_ = transferred;
            // A progress update can make the "transferred" value smaller (e.g. a
            // partial upload not completed by server, after which the "transferred"
            // value may reset to the value at the beginning of the request).
            if (this.transferred_ !== old) {
                this.notifyObservers_();
            }
        }
    }, {
        key: 'transition_',
        value: function transition_(state) {
            if (this.state_ === state) {
                return;
            }
            switch (state) {
                case _taskenums.InternalTaskState.CANCELING:
                    // TODO(andysoto):
                    // assert(this.state_ === InternalTaskState.RUNNING ||
                    //        this.state_ === InternalTaskState.PAUSING);
                    this.state_ = state;
                    if (this.request_ !== null) {
                        this.request_.cancel();
                    }
                    break;
                case _taskenums.InternalTaskState.PAUSING:
                    // TODO(andysoto):
                    // assert(this.state_ === InternalTaskState.RUNNING);
                    this.state_ = state;
                    if (this.request_ !== null) {
                        this.request_.cancel();
                    }
                    break;
                case _taskenums.InternalTaskState.RUNNING:
                    // TODO(andysoto):
                    // assert(this.state_ === InternalTaskState.PAUSED ||
                    //        this.state_ === InternalTaskState.PAUSING);
                    var wasPaused = this.state_ === _taskenums.InternalTaskState.PAUSED;
                    this.state_ = state;
                    if (wasPaused) {
                        this.notifyObservers_();
                        this.start_();
                    }
                    break;
                case _taskenums.InternalTaskState.PAUSED:
                    // TODO(andysoto):
                    // assert(this.state_ === InternalTaskState.PAUSING);
                    this.state_ = state;
                    this.notifyObservers_();
                    break;
                case _taskenums.InternalTaskState.CANCELED:
                    // TODO(andysoto):
                    // assert(this.state_ === InternalTaskState.PAUSED ||
                    //        this.state_ === InternalTaskState.CANCELING);
                    this.error_ = errors.canceled();
                    this.state_ = state;
                    this.notifyObservers_();
                    break;
                case _taskenums.InternalTaskState.ERROR:
                    // TODO(andysoto):
                    // assert(this.state_ === InternalTaskState.RUNNING ||
                    //        this.state_ === InternalTaskState.PAUSING ||
                    //        this.state_ === InternalTaskState.CANCELING);
                    this.state_ = state;
                    this.notifyObservers_();
                    break;
                case _taskenums.InternalTaskState.SUCCESS:
                    // TODO(andysoto):
                    // assert(this.state_ === InternalTaskState.RUNNING ||
                    //        this.state_ === InternalTaskState.PAUSING ||
                    //        this.state_ === InternalTaskState.CANCELING);
                    this.state_ = state;
                    this.notifyObservers_();
                    break;
            }
        }
    }, {
        key: 'completeTransitions_',
        value: function completeTransitions_() {
            switch (this.state_) {
                case _taskenums.InternalTaskState.PAUSING:
                    this.transition_(_taskenums.InternalTaskState.PAUSED);
                    break;
                case _taskenums.InternalTaskState.CANCELING:
                    this.transition_(_taskenums.InternalTaskState.CANCELED);
                    break;
                case _taskenums.InternalTaskState.RUNNING:
                    this.start_();
                    break;
                default:
                    // TODO(andysoto): assert(false);
                    break;
            }
        }
    }, {
        key: 'on',

        /**
         * Adds a callback for an event.
         * @param type The type of event to listen for.
         */
        value: function on(type) {
            var nextOrObserver = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : undefined;
            var error = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : undefined;
            var completed = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : undefined;

            var nextOrObserverMessage = 'Expected a function or an Object with one of ' + '`next`, `error`, `complete` properties.';
            var nextValidator = fbsArgs.nullFunctionSpec(true).validator;
            var observerValidator = fbsArgs.looseObjectSpec(null, true).validator;
            function nextOrObserverValidator(p) {
                try {
                    nextValidator(p);
                    return;
                } catch (e) {}
                try {
                    observerValidator(p);
                    var anyDefined = typeUtils.isJustDef(p['next']) || typeUtils.isJustDef(p['error']) || typeUtils.isJustDef(p['complete']);
                    if (!anyDefined) {
                        throw '';
                    }
                } catch (e) {
                    throw nextOrObserverMessage;
                }
            }
            var specs = [fbsArgs.stringSpec(function () {
                if (type !== _taskenums.TaskEvent.STATE_CHANGED) {
                    throw 'Expected one of the event types: [' + _taskenums.TaskEvent.STATE_CHANGED + '].';
                }
            }), fbsArgs.looseObjectSpec(nextOrObserverValidator, true), fbsArgs.nullFunctionSpec(true), fbsArgs.nullFunctionSpec(true)];
            fbsArgs.validate('on', specs, arguments);
            var self = this;
            function makeBinder(specs) {
                return function (nextOrObserver, error) {
                    if (specs !== null) {
                        fbsArgs.validate('on', specs, arguments);
                    }
                    var observer = new _observer.Observer(nextOrObserver, error, completed);
                    self.addObserver_(observer);
                    return function () {
                        self.removeObserver_(observer);
                    };
                };
            }

            var binderSpecs = [fbsArgs.looseObjectSpec(function (p) {
                if (p === null) {
                    throw nextOrObserverMessage;
                }
                nextOrObserverValidator(p);
            }), fbsArgs.nullFunctionSpec(true), fbsArgs.nullFunctionSpec(true)];
            var typeOnly = !(typeUtils.isJustDef(nextOrObserver) || typeUtils.isJustDef(error) || typeUtils.isJustDef(completed));
            if (typeOnly) {
                return makeBinder(binderSpecs);
            } else {
                return makeBinder(null)(nextOrObserver, error, completed);
            }
        }
        /**
         * This object behaves like a Promise, and resolves with its snapshot data
         * when the upload completes.
         *     The fulfillment callback. Promise chaining works as normal.
         * @param onRejected The rejection callback.
         */

    }, {
        key: 'then',
        value: function then(onFulfilled, onRejected) {
            return this.promise_.then(onFulfilled, onRejected);
        }
        /**
         * Equivalent to calling `then(null, onRejected)`.
         */

    }, {
        key: 'catch',
        value: function _catch(onRejected) {
            return this.then(null, onRejected);
        }
        /**
         * Adds the given observer.
         */

    }, {
        key: 'addObserver_',
        value: function addObserver_(observer) {
            this.observers_.push(observer);
            this.notifyObserver_(observer);
        }
        /**
         * Removes the given observer.
         */

    }, {
        key: 'removeObserver_',
        value: function removeObserver_(observer) {
            fbsArray.remove(this.observers_, observer);
        }
    }, {
        key: 'notifyObservers_',
        value: function notifyObservers_() {
            var _this9 = this;

            this.finishPromise_();
            var observers = fbsArray.clone(this.observers_);
            observers.forEach(function (observer) {
                _this9.notifyObserver_(observer);
            });
        }
    }, {
        key: 'finishPromise_',
        value: function finishPromise_() {
            if (this.resolve_ !== null) {
                var triggered = true;
                switch (fbsTaskEnums.taskStateFromInternalTaskState(this.state_)) {
                    case _taskenums.TaskState.SUCCESS:
                        (0, _async.async)(this.resolve_.bind(null, this.snapshot))();
                        break;
                    case _taskenums.TaskState.CANCELED:
                    case _taskenums.TaskState.ERROR:
                        var toCall = this.reject_;
                        (0, _async.async)(toCall.bind(null, this.error_))();
                        break;
                    default:
                        triggered = false;
                        break;
                }
                if (triggered) {
                    this.resolve_ = null;
                    this.reject_ = null;
                }
            }
        }
    }, {
        key: 'notifyObserver_',
        value: function notifyObserver_(observer) {
            var externalState = fbsTaskEnums.taskStateFromInternalTaskState(this.state_);
            switch (externalState) {
                case _taskenums.TaskState.RUNNING:
                case _taskenums.TaskState.PAUSED:
                    if (observer.next !== null) {
                        (0, _async.async)(observer.next.bind(observer, this.snapshot))();
                    }
                    break;
                case _taskenums.TaskState.SUCCESS:
                    if (observer.complete !== null) {
                        (0, _async.async)(observer.complete.bind(observer))();
                    }
                    break;
                case _taskenums.TaskState.CANCELED:
                case _taskenums.TaskState.ERROR:
                    if (observer.error !== null) {
                        (0, _async.async)(observer.error.bind(observer, this.error_))();
                    }
                    break;
                default:
                    // TODO(andysoto): assert(false);
                    if (observer.error !== null) {
                        (0, _async.async)(observer.error.bind(observer, this.error_))();
                    }
            }
        }
        /**
         * Resumes a paused task. Has no effect on a currently running or failed task.
         * @return True if the operation took effect, false if ignored.
         */

    }, {
        key: 'resume',
        value: function resume() {
            fbsArgs.validate('resume', [], arguments);
            var valid = this.state_ === _taskenums.InternalTaskState.PAUSED || this.state_ === _taskenums.InternalTaskState.PAUSING;
            if (valid) {
                this.transition_(_taskenums.InternalTaskState.RUNNING);
            }
            return valid;
        }
        /**
         * Pauses a currently running task. Has no effect on a paused or failed task.
         * @return True if the operation took effect, false if ignored.
         */

    }, {
        key: 'pause',
        value: function pause() {
            fbsArgs.validate('pause', [], arguments);
            var valid = this.state_ === _taskenums.InternalTaskState.RUNNING;
            if (valid) {
                this.transition_(_taskenums.InternalTaskState.PAUSING);
            }
            return valid;
        }
        /**
         * Cancels a currently running or paused task. Has no effect on a complete or
         * failed task.
         * @return True if the operation took effect, false if ignored.
         */

    }, {
        key: 'cancel',
        value: function cancel() {
            fbsArgs.validate('cancel', [], arguments);
            var valid = this.state_ === _taskenums.InternalTaskState.RUNNING || this.state_ === _taskenums.InternalTaskState.PAUSING;
            if (valid) {
                this.transition_(_taskenums.InternalTaskState.CANCELING);
            }
            return valid;
        }
    }, {
        key: 'snapshot',
        get: function get() {
            var externalState = fbsTaskEnums.taskStateFromInternalTaskState(this.state_);
            return new _tasksnapshot.UploadTaskSnapshot(this.transferred_, this.blob_.size(), externalState, this.metadata_, this, this.ref_);
        }
    }]);

    return UploadTask;
}();
//# sourceMappingURL=task.js.map
