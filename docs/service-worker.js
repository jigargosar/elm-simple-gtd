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

var precacheConfig = [["alarm.ogg","15a849a06ed28d19e43556b0bf2ab7ce"],["bower_components/app-layout/app-box/app-box.html","30b746d28256bc1735ef1a5877baa4f4"],["bower_components/app-layout/app-drawer-layout/app-drawer-layout.html","79afe5f8d387f551d7f49945dacc1648"],["bower_components/app-layout/app-drawer/app-drawer.html","87b795b3210cb8d575413acb77f51f24"],["bower_components/app-layout/app-grid/app-grid-style.html","2ffd83c2e13fe817f181c8e29fed3ca5"],["bower_components/app-layout/app-header-layout/app-header-layout.html","69d2e94dce2e8cd5aecfc50131f071f4"],["bower_components/app-layout/app-header/app-header.html","611b00b75388e2a548c3656087e9b4ec"],["bower_components/app-layout/app-layout-behavior/app-layout-behavior.html","354cc13dae18b154ae055036e959e2ae"],["bower_components/app-layout/app-layout.html","eedf8a32d11b9d77b785014a92148c83"],["bower_components/app-layout/app-scroll-effects/app-scroll-effects-behavior.html","387b0a58c54afa617265a50ab25c792c"],["bower_components/app-layout/app-scroll-effects/app-scroll-effects.html","f9af3b19ba0df5aea027b835f0d4e766"],["bower_components/app-layout/app-scroll-effects/effects/blend-background.html","0d375fa44800f0d196034e6a6240a5c3"],["bower_components/app-layout/app-scroll-effects/effects/fade-background.html","f3f0a1ef72443548681e08410ef8cac2"],["bower_components/app-layout/app-scroll-effects/effects/material.html","45ac7838ae5551c41616a25f7a1f1ae6"],["bower_components/app-layout/app-scroll-effects/effects/parallax-background.html","db1405dd5694b43cfce35d2522ab9825"],["bower_components/app-layout/app-scroll-effects/effects/resize-snapped-title.html","48795db4cf5b8a18cc66a976e1337a87"],["bower_components/app-layout/app-scroll-effects/effects/resize-title.html","0de52d9136a8274e0229a5b429cd7aa0"],["bower_components/app-layout/app-scroll-effects/effects/waterfall.html","a50af0d3b7b87d87f13aeb8abf049815"],["bower_components/app-layout/app-toolbar/app-toolbar.html","40628b2aaf9a599891097923c5de5a10"],["bower_components/app-layout/helpers/helpers.html","33fa00d106b9bc07ab162dbe88d1b664"],["bower_components/app-storage/app-network-status-behavior.html","850c3f38b056c58f6e29859e57b89022"],["bower_components/app-storage/app-storage-behavior.html","ea1df9352dba54788b35453905f72086"],["bower_components/firebase/firebase-app.js","01cf01b0a6ca5c6b789ad992bb3a2260"],["bower_components/firebase/firebase-auth.js","45eb86d7de447b4d13c739c21a49a968"],["bower_components/firebase/firebase-database.js","d282583e4c878c746120465e99a3db4e"],["bower_components/firebase/firebase-messaging.js","3025203a50a641644b3c691f1697dd06"],["bower_components/firebase/firebase-storage.js","0cd9f1ab79e90bf5c9378cce943763e2"],["bower_components/font-roboto/roboto.html","8b9218ffd40ebb430e7f55674cf55ffd"],["bower_components/iron-a11y-announcer/iron-a11y-announcer.html","032ddccbe04fadf233db599b63b171b9"],["bower_components/iron-a11y-keys-behavior/iron-a11y-keys-behavior.html","db18aab5d2e81d8e9d9268e6ecf72bfa"],["bower_components/iron-autogrow-textarea/iron-autogrow-textarea.html","b12f5a686abe75c718c52fa1dbb1acdb"],["bower_components/iron-behaviors/iron-button-state.html","9fb410eb4dd2cf074011b4d7565fe520"],["bower_components/iron-behaviors/iron-control-state.html","26408b231f3184ed4c861a77090782d0"],["bower_components/iron-checked-element-behavior/iron-checked-element-behavior.html","308cda98232643a0bbfe3caffeb5fedf"],["bower_components/iron-dropdown/iron-dropdown-scroll-manager.html","4941bb1f98c18a580867935163391b6c"],["bower_components/iron-dropdown/iron-dropdown.html","69de7cbbb5154bc46a1faf232c0826e2"],["bower_components/iron-fit-behavior/iron-fit-behavior.html","35bb347fbeed620a921bdb93c40363f4"],["bower_components/iron-flex-layout/iron-flex-layout-classes.html","71a8a4549c04d5279d6de408ed196f94"],["bower_components/iron-flex-layout/iron-flex-layout.html","ff9477722c978e3fdd3fbf292cc3f2fc"],["bower_components/iron-form-element-behavior/iron-form-element-behavior.html","8ea5b57ab9067df1c61dc124c496120b"],["bower_components/iron-icon/iron-icon.html","d4b7a82c9ccbbeca2b0c89f4e53ffb05"],["bower_components/iron-icons/av-icons.html","6618d2777ecdb09a97a1ecab9995d1fb"],["bower_components/iron-icons/iron-icons.html","b06b48bbd24e44ce5f592c008e254376"],["bower_components/iron-icons/notification-icons.html","52a217ebc37e6491f09bc459e8bc41b1"],["bower_components/iron-iconset-svg/iron-iconset-svg.html","7877da831e69b35918c219f1dc303416"],["bower_components/iron-image/iron-image.html","68c00a3cb8f5d13792d90fd4432dfdec"],["bower_components/iron-input/iron-input.html","c534697639484286f9cd62bf3bb6929d"],["bower_components/iron-media-query/iron-media-query.html","5fb17283155ca3ad912dafebc9f06a74"],["bower_components/iron-menu-behavior/iron-menu-behavior.html","9bbf9e8f6d6baef6264dce1a02993526"],["bower_components/iron-menu-behavior/iron-menubar-behavior.html","6bc2e5b89b8f9119e4268129b31d39fb"],["bower_components/iron-meta/iron-meta.html","c4214b55b5f4bdeee84c0caa675bb9d5"],["bower_components/iron-overlay-behavior/iron-focusables-helper.html","b935952337df172121dae50aa75d0ff6"],["bower_components/iron-overlay-behavior/iron-overlay-backdrop.html","a70e5917cb2f5bb64e53e44b2f0cd764"],["bower_components/iron-overlay-behavior/iron-overlay-behavior.html","7227fe9e747518edb9676d3d5bce48ff"],["bower_components/iron-overlay-behavior/iron-overlay-manager.html","dfcf04b2b9b17dceb9176c5d4a1233b8"],["bower_components/iron-resizable-behavior/iron-resizable-behavior.html","eb6f1817ebbfaa4b5bf9d8d079237d1d"],["bower_components/iron-scroll-target-behavior/iron-scroll-target-behavior.html","33c023f229cd353ec7d21b5a3b9e137b"],["bower_components/iron-selector/iron-multi-selectable.html","d4765be6d51eb9e5e170b7191b222aec"],["bower_components/iron-selector/iron-selectable.html","033c526023ee6429bb66dab8407497f5"],["bower_components/iron-selector/iron-selection.html","d38a136db111dc594d0e9b27c283a47a"],["bower_components/iron-validatable-behavior/iron-validatable-behavior.html","3fb306c07a03ea899a4a29b582e75567"],["bower_components/neon-animation/animations/fade-in-animation.html","32e6403f666f0a23bf0a12d9d13ac7e0"],["bower_components/neon-animation/animations/fade-out-animation.html","0b7783df10a3455dd3079d5dabfc1882"],["bower_components/neon-animation/neon-animatable-behavior.html","a0e4868750147e67dcd56b5ac5535eab"],["bower_components/neon-animation/neon-animation-behavior.html","7bea601b65a14b9d7389d806db6cbfec"],["bower_components/neon-animation/neon-animation-runner-behavior.html","0d0e9eeccf315df7c0c6330049c2cd45"],["bower_components/paper-behaviors/paper-button-behavior.html","1e6e9794c87cb389d4191911ec554890"],["bower_components/paper-behaviors/paper-checked-element-behavior.html","09e7946122f1403d25ba8489acf210f9"],["bower_components/paper-behaviors/paper-inky-focus-behavior.html","ea41e4250bc3ea30e659071b61e0df33"],["bower_components/paper-behaviors/paper-ripple-behavior.html","ed51cc379e55570173529cd58ca00b59"],["bower_components/paper-button/paper-button.html","75b7eeb8537f75878109d678fd6fd47a"],["bower_components/paper-card/paper-card.html","da4beb349731a16851be752d9f3e04f0"],["bower_components/paper-checkbox/paper-checkbox.html","b6ff5afdb4a0b9c4fa28cc01039f82b4"],["bower_components/paper-dialog-behavior/paper-dialog-behavior.html","02e7573d9959b3e056bac85c632cc939"],["bower_components/paper-dialog-behavior/paper-dialog-shared-styles.html","53a7280f7f749585af412cd0fdd02e72"],["bower_components/paper-dialog/paper-dialog.html","be9adca3e4e1f0b7f9c4cb7b33854a3b"],["bower_components/paper-dropdown-menu/paper-dropdown-menu-icons.html","4c48b1e338ed304011fb2070a299b12d"],["bower_components/paper-dropdown-menu/paper-dropdown-menu-light.html","651db286144bac7c072a71c3e1975127"],["bower_components/paper-dropdown-menu/paper-dropdown-menu-shared-styles.html","5937bb21d75c1f6a3b6a3b71cb310580"],["bower_components/paper-dropdown-menu/paper-dropdown-menu.html","076470166920533b45921878d4d40025"],["bower_components/paper-fab/paper-fab.html","775ca98d7c1538ea9d46e4621a33bdfb"],["bower_components/paper-icon-button/paper-icon-button.html","a0d061662b61cc3a515f7a53c3573704"],["bower_components/paper-input/all-imports.html","717a46fc34efdddc8f674db9d68f3056"],["bower_components/paper-input/paper-input-addon-behavior.html","9f7c79f09b3e662a7a0a0ec2210c5331"],["bower_components/paper-input/paper-input-behavior.html","cd3410b154561988640bf6c0153b1346"],["bower_components/paper-input/paper-input-char-counter.html","3afc53a558e36ccdbb0718b8da52b33a"],["bower_components/paper-input/paper-input-container.html","d90f28b41fbe59cfaae6433e4998716d"],["bower_components/paper-input/paper-input-error.html","270d241c108123335bf6dbe30d9e768f"],["bower_components/paper-input/paper-input.html","97d3e67cd7e5997b4c8e08766d598bad"],["bower_components/paper-input/paper-textarea.html","32b0efdb1f18cc263c757b49b1d1db94"],["bower_components/paper-item/all-imports.html","eaf3b3bddc5753fc0b473b76c2239f3a"],["bower_components/paper-item/paper-icon-item.html","e9c58f49e6f2b7bd093181bf49d0b5a6"],["bower_components/paper-item/paper-item-behavior.html","e8eebea30adc0d64efc784080d6ab6f7"],["bower_components/paper-item/paper-item-body.html","9bec57679c68f87f0fa82e30ed41d5a1"],["bower_components/paper-item/paper-item-shared-styles.html","a0b1e1b7020a5f28df19f661a998665a"],["bower_components/paper-item/paper-item.html","b0613096efa66d97a309df05c873bc66"],["bower_components/paper-listbox/paper-listbox.html","6fc75e3aca5cc2ae63a88f9f5f4689d0"],["bower_components/paper-material/paper-material-shared-styles.html","132d140281cbec6082b79d1e4e5cb690"],["bower_components/paper-material/paper-material.html","fee22cbd61d645bce41b56c6bc227b18"],["bower_components/paper-menu-button/paper-menu-button-animations.html","494ce3a3d3cd95ed5dd66feff0235150"],["bower_components/paper-menu-button/paper-menu-button.html","b7d8a4ae6d0d18bb81214a9c7742b87c"],["bower_components/paper-ripple/paper-ripple.html","12d5f76561faf18b359fd909833f5206"],["bower_components/paper-styles/classes/shadow.html","616b000d3a630f342e1af4054e2ae554"],["bower_components/paper-styles/classes/typography.html","00eab8e95b5f96a6106e92ec9953a40b"],["bower_components/paper-styles/color.html","2b6b926e5bd4005bdbdcd15a34a50b95"],["bower_components/paper-styles/default-theme.html","9480969fcd665e90201b506a4737fa1a"],["bower_components/paper-styles/element-styles/paper-material-styles.html","b0a38bd2eb6f4c4844d4903a46268c92"],["bower_components/paper-styles/paper-styles-classes.html","36252dc0d6bf22125e3835fce1a6ee09"],["bower_components/paper-styles/paper-styles.html","33cfef4367ded323b985916687dc51e7"],["bower_components/paper-styles/shadow.html","2fbe595f966eebe419b9b91611d6392a"],["bower_components/paper-styles/typography.html","772d86cecdd75864b7d5f6760255665c"],["bower_components/paper-tabs/paper-tab.html","9411043c954395b1483bbeb663d5f4c4"],["bower_components/paper-tabs/paper-tabs-icons.html","7efb13dd67a114aef864eb7bc28284b7"],["bower_components/paper-tabs/paper-tabs.html","10f6ef1bfaf2423507adb438c8c32037"],["bower_components/paper-toggle-button/paper-toggle-button.html","24894ae524260c2d41ffa607adcb2b59"],["bower_components/paper-tooltip/paper-tooltip.html","f4e4ac82d9c2955ff3e9bb78dee96504"],["bower_components/polymer/lib/elements/array-selector.html","76795ff2fb9aa8a158593896c4ab9932"],["bower_components/polymer/lib/elements/custom-style.html","b53cfc0076f0ecf00dc085f37bfbc115"],["bower_components/polymer/lib/elements/dom-bind.html","06633e6255127c6d39f9be371679c60d"],["bower_components/polymer/lib/elements/dom-if.html","42ffc412d545727f3de48ccd4fca741f"],["bower_components/polymer/lib/elements/dom-module.html","fd86800656c22674753f8b0b337d3e9f"],["bower_components/polymer/lib/elements/dom-repeat.html","e98e3ddcb866a5e9e279be9ce7b0e4ee"],["bower_components/polymer/lib/legacy/class.html","d3a207b2f872ae857b7db5e9d5ebfd81"],["bower_components/polymer/lib/legacy/legacy-element-mixin.html","ff864d9a4443bc1cdde84c9cb0beb3e6"],["bower_components/polymer/lib/legacy/mutable-data-behavior.html","219f20e24c7657cfd3d0672b1ee4c94e"],["bower_components/polymer/lib/legacy/polymer-fn.html","af1e8d5c6d5932154ded79a94c6ef15b"],["bower_components/polymer/lib/legacy/polymer.dom.html","622cd4cdd0a2aecaa1a7f04dab818268"],["bower_components/polymer/lib/legacy/templatizer-behavior.html","5f6455c42f1f81b88611d9091a80b51f"],["bower_components/polymer/lib/mixins/element-mixin.html","ca34f9502190aee81e4654204ca86ddf"],["bower_components/polymer/lib/mixins/gesture-event-listeners.html","ec4cce6813390dba9c9aeeb986d42803"],["bower_components/polymer/lib/mixins/mutable-data.html","b42e9fd5a0d21d0ea6d7e50837967424"],["bower_components/polymer/lib/mixins/property-accessors.html","6318e0c3d6824bffbe1c6368017b74cc"],["bower_components/polymer/lib/mixins/property-effects.html","57e19d3f1fb18bde177a011445077164"],["bower_components/polymer/lib/mixins/template-stamp.html","e9b5e3b58329dc5038857892f9ab7ae2"],["bower_components/polymer/lib/utils/array-splice.html","922f105e9326b3ebf23aca1029d8ad3c"],["bower_components/polymer/lib/utils/async.html","3b3dcc5b21c647d59ab4a491e81299ba"],["bower_components/polymer/lib/utils/boot.html","fbe284e55e70d472a732e0dd84cab58b"],["bower_components/polymer/lib/utils/case-map.html","61c3f85b8314adf2d309fdf3e97fddba"],["bower_components/polymer/lib/utils/debounce.html","b0b62601369d6a3aa7ec6d7e1cfd5e57"],["bower_components/polymer/lib/utils/flattened-nodes-observer.html","7ea457f79bf15ccd439edc0a5fb45509"],["bower_components/polymer/lib/utils/flush.html","2b4324e1cab5c4388ea129e7b17c11c9"],["bower_components/polymer/lib/utils/gestures.html","3dc1af8677716aaa0aba154a8c3a3b1d"],["bower_components/polymer/lib/utils/import-href.html","8728c208c7aca91d2f316d36bc712563"],["bower_components/polymer/lib/utils/mixin.html","fb1660a2c823d8c257022365291e69a2"],["bower_components/polymer/lib/utils/path.html","cdff0976cf841e50c7236a6c1b32a8a0"],["bower_components/polymer/lib/utils/render-status.html","9a929f20dbe0cb11548c404f1d1a6f55"],["bower_components/polymer/lib/utils/resolve-url.html","6baaaa13b817dad19102148d51a894ec"],["bower_components/polymer/lib/utils/style-gather.html","e0c98e6237a3cb3905e4a125545f18dc"],["bower_components/polymer/lib/utils/templatize.html","48b525a256281f1f677e6ab8c866e48f"],["bower_components/polymer/lib/utils/unresolved.html","a1ede4a050418cf897d096dcc8b3bc01"],["bower_components/polymer/polymer-element.html","9619497e9a7e27277c73e31cdb5f2301"],["bower_components/polymer/polymer.html","b20eb4dd015d93b8153cc6c3d79662c4"],["bower_components/polymerfire/firebase-app-script.html","4974816369ad626b6643fd448a718b5b"],["bower_components/polymerfire/firebase-app.html","8573435cae413cc91969e53dcd53db6d"],["bower_components/polymerfire/firebase-auth-script.html","05d2aea8de7dc56f27582195aad8746c"],["bower_components/polymerfire/firebase-auth.html","e3b748f7724d961c23f6667339fea201"],["bower_components/polymerfire/firebase-common-behavior.html","6baf412a50c1be33bcbc1a41f6a33027"],["bower_components/polymerfire/firebase-database-behavior.html","0c688fa1624b398df939efe82434faf9"],["bower_components/polymerfire/firebase-database-script.html","cef0dc8b12eaeb8f1b32a239d40086ea"],["bower_components/polymerfire/firebase-document.html","419df1e80105c009632a32cff79fdcb1"],["bower_components/polymerfire/firebase-messaging-script.html","cf01ea25976351c84587301d4d0b1c17"],["bower_components/polymerfire/firebase-messaging.html","a6182cec686b4de9f8965784c6177651"],["bower_components/polymerfire/firebase-query.html","bb6d553f49aeeefeb4c339dfa65c69c2"],["bower_components/polymerfire/firebase-storage-script.html","76045e7472c15c76dcc3fa6dda316b4c"],["bower_components/polymerfire/polymerfire.html","55004502888bc1f2b085c20598271ce9"],["bower_components/pouchdb/dist/pouchdb.js","b2a876f2a6f0bf1ee3a9a4c6619494e3"],["bower_components/shadycss/apply-shim.html","f220299c2be1b5040111843d640b70a5"],["bower_components/shadycss/apply-shim.min.js","af698c6f3ce325b929832a5d5af28c9a"],["bower_components/shadycss/custom-style-interface.html","0a68ea0f3af7bcb1ca6617e512f720cb"],["bower_components/shadycss/custom-style-interface.min.js","01a88020e76782fca9a054cd5eaab952"],["bower_components/web-animations-js/web-animations-next-lite.min.html","dc4a970b1dcdb30424a28ad2b9392790"],["bower_components/web-animations-js/web-animations-next-lite.min.js","15d16a62a8a0e8475a0daa1e025b6510"],["common.js","fe4bc30c285f1ad01851a5d30bdf262f"],["favicon.ico","3479907595756ea76609ebadd66feaeb"],["imports.html","9e3574e8a3effcdceedfcc0dd0206d99"],["index.html","709e2f4054575d65eab0732cb4e16298"],["logo.ico","3479907595756ea76609ebadd66feaeb"],["logo.png","83eee072844add651724f1aa3d33864b"],["main.js","653aba7c98855f7a41ea041272a64249"],["manifest.json","17907b1fce6d893aeaaae735af9965ac"],["simplegtd.png","768019c00d401bce578381b30c0d5081"],["stack.ico","17b48e461e0c4fd7cc5c0cd2ba1dc3c4"],["stack.png","3d665038e72997c9d40f2f77fa08e9a7"]];
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
    var directoryIndex = '';
    if (!shouldRespond && directoryIndex) {
      url = addDirectoryIndex(url, directoryIndex);
      shouldRespond = urlsToCacheKeys.has(url);
    }

    // If shouldRespond is still false, check to see if this is a navigation
    // request, and if so, whether the URL matches navigateFallbackWhitelist.
    var navigateFallback = 'index.html';
    if (!shouldRespond &&
        navigateFallback &&
        (event.request.mode === 'navigate') &&
        isPathWhitelisted(["\\/[^\\/\\.]*(\\?|$)"], event.request.url)) {
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

