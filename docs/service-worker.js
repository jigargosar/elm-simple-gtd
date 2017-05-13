/**
 * Copyright 2016 Google Inc. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
*/

// DO NOT EDIT THIS GENERATED OUTPUT DIRECTLY!
// This file should be overwritten as part of your build process.
// If you need to extend the behavior of the generated service worker, the best approach is to write
// additional code and include it using the importScripts option:
//   https://github.com/GoogleChrome/sw-precache#importscripts-arraystring
//
// Alternatively, it's possible to make changes to the underlying template file and then use that as the
// new base for generating output, via the templateFilePath option:
//   https://github.com/GoogleChrome/sw-precache#templatefilepath-string
//
// If you go that route, make sure that whenever you update your sw-precache dependency, you reconcile any
// changes made to this original template file with your modified copy.

// This generated service worker JavaScript will precache your site's resources.
// The code needs to be saved in a .js file at the top-level of your site, and registered
// from your pages in order to be used. See
// https://github.com/googlechrome/sw-precache/blob/master/demo/app/js/service-worker-registration.js
// for an example of how you can register this script and handle various service worker events.

/* eslint-env worker, serviceworker */
/* eslint-disable indent, no-unused-vars, no-multiple-empty-lines, max-nested-callbacks, space-before-function-paren, quotes, comma-spacing */
'use strict';

var precacheConfig = [["/alarm.ogg","15a849a06ed28d19e43556b0bf2ab7ce"],["/bower_components/app-layout/app-box/app-box.html","bac31a8fac30b5b5ddeb26c1084fe2ba"],["/bower_components/app-layout/app-drawer-layout/app-drawer-layout.html","3dad14731165468afe4976b5497318f1"],["/bower_components/app-layout/app-drawer/app-drawer.html","f0255ae77bd7b7972c905a4d3640d07d"],["/bower_components/app-layout/app-grid/app-grid-style.html","2ffd83c2e13fe817f181c8e29fed3ca5"],["/bower_components/app-layout/app-header-layout/app-header-layout.html","c2475b9bb954adeb6487d1cebdfb59bb"],["/bower_components/app-layout/app-header/app-header.html","03b3c991d6af95dd0d7996d2737f33b8"],["/bower_components/app-layout/app-layout-behavior/app-layout-behavior.html","367a7614fb35d67d63e487349626a47b"],["/bower_components/app-layout/app-layout.html","eedf8a32d11b9d77b785014a92148c83"],["/bower_components/app-layout/app-scroll-effects/app-scroll-effects-behavior.html","ae5392d7b36a7b5050be3d48fb5b83b6"],["/bower_components/app-layout/app-scroll-effects/app-scroll-effects.html","f9af3b19ba0df5aea027b835f0d4e766"],["/bower_components/app-layout/app-scroll-effects/effects/blend-background.html","322b9237b050de5cf2c53f126d7d2881"],["/bower_components/app-layout/app-scroll-effects/effects/fade-background.html","b5e9b5fbe759f5f1212c3dc319b4b684"],["/bower_components/app-layout/app-scroll-effects/effects/material.html","c0510fe3848f562f075d81f065cb8034"],["/bower_components/app-layout/app-scroll-effects/effects/parallax-background.html","a41cf1fd2babbaabfd231aa46ccbaada"],["/bower_components/app-layout/app-scroll-effects/effects/resize-snapped-title.html","cb0f39370f9844ddd2c3e05949fd8810"],["/bower_components/app-layout/app-scroll-effects/effects/resize-title.html","43fef1d0c2136ceeaebdb16caf0903de"],["/bower_components/app-layout/app-scroll-effects/effects/waterfall.html","d6a5a3bd738dcae5e4ba52e325d8912c"],["/bower_components/app-layout/app-toolbar/app-toolbar.html","4dfe569387228612f843e8cf4a9411f0"],["/bower_components/app-layout/helpers/helpers.html","56e1a45e5951803b7d9ef7905b425d50"],["/bower_components/app-storage/app-network-status-behavior.html","ec3dc615ff39a9553185adcb593185f6"],["/bower_components/app-storage/app-storage-behavior.html","c82a0fca6d7fcdcb8a4b0a7c73f77c43"],["/bower_components/firebase/firebase-app.js","9a447f87bfa89415a34758f9e14d9430"],["/bower_components/firebase/firebase-auth.js","0cd20e835b6fa9732a800ef0ffcb5e6a"],["/bower_components/firebase/firebase-database.js","3a1800ea377e98f027a5ca50fdad982e"],["/bower_components/firebase/firebase-messaging.js","3124dee08663d586bb91402d665f0ad7"],["/bower_components/firebase/firebase-storage.js","a63c0647cc14458b9988ee521539e2ab"],["/bower_components/font-roboto/roboto.html","8b9218ffd40ebb430e7f55674cf55ffd"],["/bower_components/iron-a11y-announcer/iron-a11y-announcer.html","c40ff6a4de2cc740032a7276bfc2e186"],["/bower_components/iron-a11y-keys-behavior/iron-a11y-keys-behavior.html","99d81b269533aa804f5bd76dbd28063d"],["/bower_components/iron-ajax/iron-ajax.html","85a77d53cd5d2bcd8bf90aa7150925bf"],["/bower_components/iron-ajax/iron-request.html","632f6009afd6b2f130694cc84d616bde"],["/bower_components/iron-autogrow-textarea/iron-autogrow-textarea.html","3af0db0a7fd6e23b46759015f86ed2f7"],["/bower_components/iron-behaviors/iron-button-state.html","22988823389d803c32847d3cd8a77c23"],["/bower_components/iron-behaviors/iron-control-state.html","1000bbd632019690192d4ecfef03d27f"],["/bower_components/iron-checked-element-behavior/iron-checked-element-behavior.html","56b4e6a9ecef59550c4e211e52821a33"],["/bower_components/iron-dropdown/iron-dropdown-scroll-manager.html","7fe21e43a49daef417b669d5eaf6ad12"],["/bower_components/iron-dropdown/iron-dropdown.html","8b91fe5699e1785f4dca2641ecbf071e"],["/bower_components/iron-fit-behavior/iron-fit-behavior.html","aae54ba009a9a12f7f4464c6ad88a231"],["/bower_components/iron-flex-layout/iron-flex-layout-classes.html","71a8a4549c04d5279d6de408ed196f94"],["/bower_components/iron-flex-layout/iron-flex-layout.html","ff9477722c978e3fdd3fbf292cc3f2fc"],["/bower_components/iron-form-element-behavior/iron-form-element-behavior.html","b0ea9f70893432bf1192810f6084ddfc"],["/bower_components/iron-form/iron-form.html","141c97b15f237fdb2ab69075fe052e76"],["/bower_components/iron-icon/iron-icon.html","5e5c46110d3adec16bfd08884a1c1604"],["/bower_components/iron-icons/av-icons.html","6618d2777ecdb09a97a1ecab9995d1fb"],["/bower_components/iron-icons/iron-icons.html","b06b48bbd24e44ce5f592c008e254376"],["/bower_components/iron-icons/notification-icons.html","52a217ebc37e6491f09bc459e8bc41b1"],["/bower_components/iron-iconset-svg/iron-iconset-svg.html","32e6f9fabee62d464f9a37da0b74faf7"],["/bower_components/iron-image/iron-image.html","f38e79b8ddf7a762ff4e1aa43a6da93d"],["/bower_components/iron-input/iron-input.html","e2a070392bbed48e7e0d5faa5a93aa04"],["/bower_components/iron-media-query/iron-media-query.html","103b8c2685ae8dce759f80a27db7b843"],["/bower_components/iron-menu-behavior/iron-menu-behavior.html","cfd29d6772087db38a8e50179dee31be"],["/bower_components/iron-menu-behavior/iron-menubar-behavior.html","22bb5705921aadd931a2c7dba9545b21"],["/bower_components/iron-meta/iron-meta.html","d27c7ef1f27ab40eeb33c8a49c6a9559"],["/bower_components/iron-overlay-behavior/iron-focusables-helper.html","2da7d5a90ffc7d0d249d3b99d4122abc"],["/bower_components/iron-overlay-behavior/iron-overlay-backdrop.html","fb00d36d0f54d7fd4e5c1f73ea7c1081"],["/bower_components/iron-overlay-behavior/iron-overlay-behavior.html","aa624fc6ac8d75313bb9ca737d8da1bb"],["/bower_components/iron-overlay-behavior/iron-overlay-manager.html","d75fdf1fb0739123694058c3f729b371"],["/bower_components/iron-resizable-behavior/iron-resizable-behavior.html","c563ff7f304f1d82ecd2553a043d61bc"],["/bower_components/iron-scroll-target-behavior/iron-scroll-target-behavior.html","5137bdbe4a5f67c7d8300692b8f8b47e"],["/bower_components/iron-selector/iron-multi-selectable.html","4e3b3fdd2927aad1145193b974cd4a1b"],["/bower_components/iron-selector/iron-selectable.html","f31251ed6623a798417adf40f2333333"],["/bower_components/iron-selector/iron-selection.html","64c9940f918c3e3209b7bce69dcbc696"],["/bower_components/iron-validatable-behavior/iron-validatable-behavior.html","b704d0d7dc5f14f1c24950f578a152b2"],["/bower_components/neon-animation/animations/fade-in-animation.html","187aa2266ad5671d203fdb66f903899b"],["/bower_components/neon-animation/animations/fade-out-animation.html","950a609e8627bc620c7bb7a65eadc236"],["/bower_components/neon-animation/neon-animatable-behavior.html","dc473670228c923487f6569c677a58be"],["/bower_components/neon-animation/neon-animation-behavior.html","567d350145a8e8a45441ebaa32fa61ad"],["/bower_components/neon-animation/neon-animation-runner-behavior.html","7f9dc802538f683f7379f933e35458cc"],["/bower_components/paper-behaviors/paper-button-behavior.html","e6c0ee5398b61d0c9d72105e86664ab2"],["/bower_components/paper-behaviors/paper-checked-element-behavior.html","e6bf6eae415299eadf77253224ccae36"],["/bower_components/paper-behaviors/paper-inky-focus-behavior.html","56640043c916310915c18e5f520086e9"],["/bower_components/paper-behaviors/paper-ripple-behavior.html","6fa17ee046284a249f38a22562fbde43"],["/bower_components/paper-button/paper-button.html","0a7a0a80795a79749e1670ac9c75ef52"],["/bower_components/paper-card/paper-card.html","b6ee31d7857dce5ad83d16675faa8bf0"],["/bower_components/paper-checkbox/paper-checkbox.html","1b1f432de61a8e547d044085ab499b6d"],["/bower_components/paper-dialog-behavior/paper-dialog-behavior.html","7b31d4151daf76160f22b7bbae018ef0"],["/bower_components/paper-dialog-behavior/paper-dialog-shared-styles.html","53a7280f7f749585af412cd0fdd02e72"],["/bower_components/paper-dialog/paper-dialog.html","b79137726f7c64033a216c98705efec0"],["/bower_components/paper-dropdown-menu/paper-dropdown-menu-icons.html","4c48b1e338ed304011fb2070a299b12d"],["/bower_components/paper-dropdown-menu/paper-dropdown-menu-light.html","752b80b25e8b09044b1db793d68504b8"],["/bower_components/paper-dropdown-menu/paper-dropdown-menu-shared-styles.html","5937bb21d75c1f6a3b6a3b71cb310580"],["/bower_components/paper-dropdown-menu/paper-dropdown-menu.html","0569c1297c46f2049e1cffe51a32504d"],["/bower_components/paper-fab/paper-fab.html","b175a0079e61a74d3c735a2a1efe8036"],["/bower_components/paper-icon-button/paper-icon-button.html","884ec16d92abde6deee53ec461e7cbf3"],["/bower_components/paper-input/all-imports.html","717a46fc34efdddc8f674db9d68f3056"],["/bower_components/paper-input/paper-input-addon-behavior.html","5e2ac86aefaf3530c3cff1015c14968b"],["/bower_components/paper-input/paper-input-behavior.html","921b12eacad3347facbcfa0cd5c18e18"],["/bower_components/paper-input/paper-input-char-counter.html","df47724185b01daef1518d74f9c3b0a6"],["/bower_components/paper-input/paper-input-container.html","db08758e3e2638b20b251e618611b707"],["/bower_components/paper-input/paper-input-error.html","4eefb8f2f28384f3a62129adbc390039"],["/bower_components/paper-input/paper-input.html","f10cacda7413a553bcbcf1e856f2836f"],["/bower_components/paper-input/paper-textarea.html","cb52ecd421b837a7bb90366f63c1f1b8"],["/bower_components/paper-item/all-imports.html","eaf3b3bddc5753fc0b473b76c2239f3a"],["/bower_components/paper-item/paper-icon-item.html","1138d477ad8be02824a278acb251bcf6"],["/bower_components/paper-item/paper-item-behavior.html","44364c95aa268eeca1339d9bad0b83c0"],["/bower_components/paper-item/paper-item-body.html","d42c97857e96f71b08b7fefb6196f7f9"],["/bower_components/paper-item/paper-item-shared-styles.html","a0b1e1b7020a5f28df19f661a998665a"],["/bower_components/paper-item/paper-item.html","55910ea08e97d0341b908b753aa53d8a"],["/bower_components/paper-listbox/paper-listbox.html","240ca53b5fb96a70f7e218a30b309cb7"],["/bower_components/paper-material/paper-material-shared-styles.html","132d140281cbec6082b79d1e4e5cb690"],["/bower_components/paper-material/paper-material.html","55f23661b19d528796ef83e1a7fdcea4"],["/bower_components/paper-menu-button/paper-menu-button-animations.html","c30f25bdcda4d80d33bdc36115011efe"],["/bower_components/paper-menu-button/paper-menu-button.html","f7dedfcf2ea7384044bf126226ab0415"],["/bower_components/paper-ripple/paper-ripple.html","75edd5d4ae179e1e7ba8bd80020f15f4"],["/bower_components/paper-styles/classes/shadow.html","616b000d3a630f342e1af4054e2ae554"],["/bower_components/paper-styles/classes/typography.html","00eab8e95b5f96a6106e92ec9953a40b"],["/bower_components/paper-styles/color.html","2b6b926e5bd4005bdbdcd15a34a50b95"],["/bower_components/paper-styles/default-theme.html","9480969fcd665e90201b506a4737fa1a"],["/bower_components/paper-styles/element-styles/paper-material-styles.html","b0a38bd2eb6f4c4844d4903a46268c92"],["/bower_components/paper-styles/paper-styles-classes.html","36252dc0d6bf22125e3835fce1a6ee09"],["/bower_components/paper-styles/paper-styles.html","33cfef4367ded323b985916687dc51e7"],["/bower_components/paper-styles/shadow.html","2fbe595f966eebe419b9b91611d6392a"],["/bower_components/paper-styles/typography.html","772d86cecdd75864b7d5f6760255665c"],["/bower_components/paper-tabs/paper-tab.html","fa461cb45c9cbd0cde0bfe6e17fb35cd"],["/bower_components/paper-tabs/paper-tabs-icons.html","7efb13dd67a114aef864eb7bc28284b7"],["/bower_components/paper-tabs/paper-tabs.html","1327de280b68bcd6f7dfa17c83746086"],["/bower_components/paper-toggle-button/paper-toggle-button.html","09cd2bde331088cbea72bfdb61c78a69"],["/bower_components/paper-tooltip/paper-tooltip.html","b01fc17d612855149064cefefb676ab5"],["/bower_components/polymer/lib/elements/array-selector.html","f8f7054cc7f541e290bf7d71a9d75aa9"],["/bower_components/polymer/lib/elements/custom-style.html","899abec7dba69fe2ec47e56416b0ba69"],["/bower_components/polymer/lib/elements/dom-bind.html","76ecf27f543ed8c7fc0448fe7c7fe093"],["/bower_components/polymer/lib/elements/dom-if.html","2eea4c869696b0dca40c6d8ba49f3575"],["/bower_components/polymer/lib/elements/dom-module.html","e7c08a2fc1a83f942636dbce6aab4a3e"],["/bower_components/polymer/lib/elements/dom-repeat.html","0f7f491109d514b4b70cd441190044d9"],["/bower_components/polymer/lib/legacy/class.html","2a6838c5ceed093b4c99703ed4be79a6"],["/bower_components/polymer/lib/legacy/legacy-element-mixin.html","df83b20c2732b04db6d19861c5e3583f"],["/bower_components/polymer/lib/legacy/mutable-data-behavior.html","1fb9d8e855c24d7a7291aed53b8fc1d3"],["/bower_components/polymer/lib/legacy/polymer-fn.html","2d6f51d4122e91705e0f1dd86141904a"],["/bower_components/polymer/lib/legacy/polymer.dom.html","94f4a45db24ae5b44622338d7f079f9b"],["/bower_components/polymer/lib/legacy/templatizer-behavior.html","bfecd8838245efff5c5047a61887899a"],["/bower_components/polymer/lib/mixins/element-mixin.html","b3611fbbdef0787006392451ccb51896"],["/bower_components/polymer/lib/mixins/gesture-event-listeners.html","b0c400dad3d6ed1827ef018b7c8dabc5"],["/bower_components/polymer/lib/mixins/mutable-data.html","063973be08d4714a13a2d8bdab7a5ebb"],["/bower_components/polymer/lib/mixins/property-accessors.html","07b59441ce89df821b1433e36ac1a66e"],["/bower_components/polymer/lib/mixins/property-effects.html","8aaffbb3c97ac57fa3f2f7bb47685a1f"],["/bower_components/polymer/lib/mixins/template-stamp.html","2ea4fc5a740349a57729736cd14870ae"],["/bower_components/polymer/lib/utils/array-splice.html","7e7a1d82e1a925e7b6b7ad0e54ef6b3e"],["/bower_components/polymer/lib/utils/async.html","5a250fe57b78fa35695f956465fb38d5"],["/bower_components/polymer/lib/utils/boot.html","9f51a9b310885efeba1bae26f3c8ed4c"],["/bower_components/polymer/lib/utils/case-map.html","5aba7ccdd3fee1ecdd673f2eab0fb80e"],["/bower_components/polymer/lib/utils/debounce.html","d1d1742e42d85e48d1d14a2b3a278444"],["/bower_components/polymer/lib/utils/flattened-nodes-observer.html","ef93de108416c9d3f43271edd8a4e8b3"],["/bower_components/polymer/lib/utils/flush.html","6cc5ccb3c251a3c397457db4d9085207"],["/bower_components/polymer/lib/utils/gestures.html","8ac1a21ba83a57bd2d0d1a10c66765a4"],["/bower_components/polymer/lib/utils/import-href.html","5c403aa7a8a377a819ad2765dd18a7d1"],["/bower_components/polymer/lib/utils/mixin.html","d189cec772db4948acc3de5b26527a04"],["/bower_components/polymer/lib/utils/path.html","0e91db958c7d2535c774b991ebc2c773"],["/bower_components/polymer/lib/utils/render-status.html","5d6dee87635178f8841a8d1abab39bdf"],["/bower_components/polymer/lib/utils/resolve-url.html","2f84b9dfacf50583eaf9ce243cc15867"],["/bower_components/polymer/lib/utils/style-gather.html","987b59a215b94eac85b2348211a54fdd"],["/bower_components/polymer/lib/utils/templatize.html","0c53c1f07143b29bba6bfdc9d3366ed1"],["/bower_components/polymer/lib/utils/unresolved.html","9ffbd489a9721ed9a1ad95f4b441bc84"],["/bower_components/polymer/polymer-element.html","85ef528072a70a06d2b3ff5eb178a284"],["/bower_components/polymer/polymer.html","2e0fcfd0c7c72f4f1628aa56167237c9"],["/bower_components/polymerfire/firebase-app-script.html","4974816369ad626b6643fd448a718b5b"],["/bower_components/polymerfire/firebase-app.html","cc2189a6e348c74fc26f100092cdf097"],["/bower_components/polymerfire/firebase-auth-script.html","05d2aea8de7dc56f27582195aad8746c"],["/bower_components/polymerfire/firebase-auth.html","aecf5d04dd9185cce28f7edc8d7f982b"],["/bower_components/polymerfire/firebase-common-behavior.html","14f8693832285beda0a0dfba9bb97c59"],["/bower_components/polymerfire/firebase-database-behavior.html","3dc1fb08c43e94f8eaab5bfbc1b11c01"],["/bower_components/polymerfire/firebase-database-script.html","cef0dc8b12eaeb8f1b32a239d40086ea"],["/bower_components/polymerfire/firebase-document.html","c7ceaf588e5e10e68f9b4a7fd955b37f"],["/bower_components/polymerfire/firebase-messaging-script.html","cf01ea25976351c84587301d4d0b1c17"],["/bower_components/polymerfire/firebase-messaging.html","2005b7dd11013333d12a44010039255e"],["/bower_components/polymerfire/firebase-query.html","14381473ba6aeccb47681b7f1be2db2d"],["/bower_components/polymerfire/firebase-storage-script.html","76045e7472c15c76dcc3fa6dda316b4c"],["/bower_components/polymerfire/polymerfire.html","55004502888bc1f2b085c20598271ce9"],["/bower_components/shadycss/apply-shim.html","f220299c2be1b5040111843d640b70a5"],["/bower_components/shadycss/apply-shim.min.js","ceeaad90c0e6d9265c81f0ddf3a6612c"],["/bower_components/shadycss/custom-style-interface.html","0a68ea0f3af7bcb1ca6617e512f720cb"],["/bower_components/shadycss/custom-style-interface.min.js","c87605744df92a24f8a3faa0776bfd2e"],["/bower_components/web-animations-js/web-animations-next-lite.min.html","dc4a970b1dcdb30424a28ad2b9392790"],["/bower_components/web-animations-js/web-animations-next-lite.min.js","af49292cf4e004b70ec80330912f8154"],["/common.js","c1cec9b688106fe9d4894d669a3b6c7d"],["/favicon.ico","17b48e461e0c4fd7cc5c0cd2ba1dc3c4"],["/imports.html","87cc94750f4d5806a4d311be784984bc"],["/index.html","abe7f36b76b6cf5bfdc960606e0e9c62"],["/main.js","eda1ce3f0c90a504f60c909021a2fa6d"],["/manifest.json","c5a7a8d2d3914b2740e11a9bc922653d"],["/stack.png","3d665038e72997c9d40f2f77fa08e9a7"]];
var cacheName = 'sw-precache-v3--' + (self.registration ? self.registration.scope : '');


var ignoreUrlParametersMatching = [/^utm_/];



var addDirectoryIndex = function (originalUrl, index) {
    var url = new URL(originalUrl);
    if (url.pathname.slice(-1) === '/') {
      url.pathname += index;
    }
    return url.toString();
  };

var cleanResponse = function (originalResponse) {
    // If this is not a redirected response, then we don't have to do anything.
    if (!originalResponse.redirected) {
      return Promise.resolve(originalResponse);
    }

    // Firefox 50 and below doesn't support the Response.body stream, so we may
    // need to read the entire body to memory as a Blob.
    var bodyPromise = 'body' in originalResponse ?
      Promise.resolve(originalResponse.body) :
      originalResponse.blob();

    return bodyPromise.then(function(body) {
      // new Response() is happy when passed either a stream or a Blob.
      return new Response(body, {
        headers: originalResponse.headers,
        status: originalResponse.status,
        statusText: originalResponse.statusText
      });
    });
  };

var createCacheKey = function (originalUrl, paramName, paramValue,
                           dontCacheBustUrlsMatching) {
    // Create a new URL object to avoid modifying originalUrl.
    var url = new URL(originalUrl);

    // If dontCacheBustUrlsMatching is not set, or if we don't have a match,
    // then add in the extra cache-busting URL parameter.
    if (!dontCacheBustUrlsMatching ||
        !(url.pathname.match(dontCacheBustUrlsMatching))) {
      url.search += (url.search ? '&' : '') +
        encodeURIComponent(paramName) + '=' + encodeURIComponent(paramValue);
    }

    return url.toString();
  };

var isPathWhitelisted = function (whitelist, absoluteUrlString) {
    // If the whitelist is empty, then consider all URLs to be whitelisted.
    if (whitelist.length === 0) {
      return true;
    }

    // Otherwise compare each path regex to the path of the URL passed in.
    var path = (new URL(absoluteUrlString)).pathname;
    return whitelist.some(function(whitelistedPathRegex) {
      return path.match(whitelistedPathRegex);
    });
  };

var stripIgnoredUrlParameters = function (originalUrl,
    ignoreUrlParametersMatching) {
    var url = new URL(originalUrl);
    // Remove the hash; see https://github.com/GoogleChrome/sw-precache/issues/290
    url.hash = '';

    url.search = url.search.slice(1) // Exclude initial '?'
      .split('&') // Split into an array of 'key=value' strings
      .map(function(kv) {
        return kv.split('='); // Split each 'key=value' string into a [key, value] array
      })
      .filter(function(kv) {
        return ignoreUrlParametersMatching.every(function(ignoredRegex) {
          return !ignoredRegex.test(kv[0]); // Return true iff the key doesn't match any of the regexes.
        });
      })
      .map(function(kv) {
        return kv.join('='); // Join each [key, value] array into a 'key=value' string
      })
      .join('&'); // Join the array of 'key=value' strings into a string with '&' in between each

    return url.toString();
  };


var hashParamName = '_sw-precache';
var urlsToCacheKeys = new Map(
  precacheConfig.map(function(item) {
    var relativeUrl = item[0];
    var hash = item[1];
    var absoluteUrl = new URL(relativeUrl, self.location);
    var cacheKey = createCacheKey(absoluteUrl, hashParamName, hash, false);
    return [absoluteUrl.toString(), cacheKey];
  })
);

function setOfCachedUrls(cache) {
  return cache.keys().then(function(requests) {
    return requests.map(function(request) {
      return request.url;
    });
  }).then(function(urls) {
    return new Set(urls);
  });
}

self.addEventListener('install', function(event) {
  event.waitUntil(
    caches.open(cacheName).then(function(cache) {
      return setOfCachedUrls(cache).then(function(cachedUrls) {
        return Promise.all(
          Array.from(urlsToCacheKeys.values()).map(function(cacheKey) {
            // If we don't have a key matching url in the cache already, add it.
            if (!cachedUrls.has(cacheKey)) {
              var request = new Request(cacheKey, {credentials: 'same-origin'});
              return fetch(request).then(function(response) {
                // Bail out of installation unless we get back a 200 OK for
                // every request.
                if (!response.ok) {
                  throw new Error('Request for ' + cacheKey + ' returned a ' +
                    'response with status ' + response.status);
                }

                return cleanResponse(response).then(function(responseToCache) {
                  return cache.put(cacheKey, responseToCache);
                });
              });
            }
          })
        );
      });
    }).then(function() {
      
      // Force the SW to transition from installing -> active state
      return self.skipWaiting();
      
    })
  );
});

self.addEventListener('activate', function(event) {
  var setOfExpectedUrls = new Set(urlsToCacheKeys.values());

  event.waitUntil(
    caches.open(cacheName).then(function(cache) {
      return cache.keys().then(function(existingRequests) {
        return Promise.all(
          existingRequests.map(function(existingRequest) {
            if (!setOfExpectedUrls.has(existingRequest.url)) {
              return cache.delete(existingRequest);
            }
          })
        );
      });
    }).then(function() {
      
      return self.clients.claim();
      
    })
  );
});


self.addEventListener('fetch', function(event) {
  if (event.request.method === 'GET') {
    // Should we call event.respondWith() inside this fetch event handler?
    // This needs to be determined synchronously, which will give other fetch
    // handlers a chance to handle the request if need be.
    var shouldRespond;

    // First, remove all the ignored parameters and hash fragment, and see if we
    // have that URL in our cache. If so, great! shouldRespond will be true.
    var url = stripIgnoredUrlParameters(event.request.url, ignoreUrlParametersMatching);
    shouldRespond = urlsToCacheKeys.has(url);

    // If shouldRespond is false, check again, this time with 'index.html'
    // (or whatever the directoryIndex option is set to) at the end.
    var directoryIndex = 'index.html';
    if (!shouldRespond && directoryIndex) {
      url = addDirectoryIndex(url, directoryIndex);
      shouldRespond = urlsToCacheKeys.has(url);
    }

    // If shouldRespond is still false, check to see if this is a navigation
    // request, and if so, whether the URL matches navigateFallbackWhitelist.
    var navigateFallback = '';
    if (!shouldRespond &&
        navigateFallback &&
        (event.request.mode === 'navigate') &&
        isPathWhitelisted([], event.request.url)) {
      url = new URL(navigateFallback, self.location).toString();
      shouldRespond = urlsToCacheKeys.has(url);
    }

    // If shouldRespond was set to true at any point, then call
    // event.respondWith(), using the appropriate cache key.
    if (shouldRespond) {
      event.respondWith(
        caches.open(cacheName).then(function(cache) {
          return cache.match(urlsToCacheKeys.get(url)).then(function(response) {
            if (response) {
              return response;
            }
            throw Error('The cached response that was expected is missing.');
          });
        }).catch(function(e) {
          // Fall back to just fetch()ing the request if some unexpected error
          // prevented the cached response from being valid.
          console.warn('Couldn\'t serve response for "%s" from cache: %O', event.request.url, e);
          return fetch(event.request);
        })
      );
    }
  }
});







importScripts("notification-sw.js");

