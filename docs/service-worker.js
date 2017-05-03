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

var precacheConfig = [["/alarm.ogg","15a849a06ed28d19e43556b0bf2ab7ce"],["/bower_components/app-layout/app-box/app-box.html","4878f1ef991bca5ec2b816bb7ebf132e"],["/bower_components/app-layout/app-drawer-layout/app-drawer-layout.html","0876393f1b80b9293e4dc4eb9422653c"],["/bower_components/app-layout/app-drawer/app-drawer.html","9fd0cd410f7a14b769aa0b1cf31c6e16"],["/bower_components/app-layout/app-grid/app-grid-style.html","0410c7143a61d8924bfff86235ceb1d2"],["/bower_components/app-layout/app-header-layout/app-header-layout.html","40d79051499c67a61af1f7ec4a3bd871"],["/bower_components/app-layout/app-header/app-header.html","229c82b7666c6c6c0ca310c6ff5e93b2"],["/bower_components/app-layout/app-layout-behavior/app-layout-behavior.html","afefed474b2e19f091ad578bf11e7bf2"],["/bower_components/app-layout/app-layout.html","a6f2759e048fb0497a8d29646e3c69bf"],["/bower_components/app-layout/app-scroll-effects/app-scroll-effects-behavior.html","8c5d09ec0053ce1f4ebe08e93c9657ce"],["/bower_components/app-layout/app-scroll-effects/app-scroll-effects.html","334eac7f54a828baedbe8f09574571b7"],["/bower_components/app-layout/app-scroll-effects/effects/blend-background.html","dead12f7659321c7fe4928aae467519f"],["/bower_components/app-layout/app-scroll-effects/effects/fade-background.html","35e9b86069d272d5e086d324e6afa01a"],["/bower_components/app-layout/app-scroll-effects/effects/material.html","26f969f3f845031af5f3c728d550638b"],["/bower_components/app-layout/app-scroll-effects/effects/parallax-background.html","6ca6cd1f7972a53c6b5d38360f39459e"],["/bower_components/app-layout/app-scroll-effects/effects/resize-snapped-title.html","22c4d4328472d5dc35906793fe731a2f"],["/bower_components/app-layout/app-scroll-effects/effects/resize-title.html","e0d5f4348d3ca12d5f309b11fa6a7e4b"],["/bower_components/app-layout/app-scroll-effects/effects/waterfall.html","059e8ca24132d7f55f5b972ba3459ff6"],["/bower_components/app-layout/app-toolbar/app-toolbar.html","4cab4ff242890b4b0d2f8aea6378823e"],["/bower_components/app-layout/helpers/helpers.html","4329e16ecb3d38b9f16360a1b6ad6fe3"],["/bower_components/font-roboto/roboto.html","196f915c2bb639c50e0748d057754841"],["/bower_components/iron-a11y-announcer/iron-a11y-announcer.html","0728d32ca62675f5088b63a6aa60ab4e"],["/bower_components/iron-a11y-keys-behavior/iron-a11y-keys-behavior.html","7440176796d324569bd0f45139250f6f"],["/bower_components/iron-ajax/iron-ajax.html","48e76720d4c65fffa81dd7281d7f9b63"],["/bower_components/iron-ajax/iron-request.html","a19ef82655be03f7129bc58d71089b82"],["/bower_components/iron-autogrow-textarea/iron-autogrow-textarea.html","730a1538f364af3eee01bde35537055d"],["/bower_components/iron-behaviors/iron-button-state.html","49775c63df22d46cec1377ef6d20c037"],["/bower_components/iron-behaviors/iron-control-state.html","ba130c38639bec8358c840f676dca6fd"],["/bower_components/iron-checked-element-behavior/iron-checked-element-behavior.html","ffbd60e7b7389c26b0f89ed892cbb605"],["/bower_components/iron-dropdown/iron-dropdown-scroll-manager.html","bb50b290cd2518178f41a0b08d5d3f52"],["/bower_components/iron-dropdown/iron-dropdown.html","24334866ad6d43de8008b0a91349455f"],["/bower_components/iron-fit-behavior/iron-fit-behavior.html","94789268c438acfe92363c05486c23f4"],["/bower_components/iron-flex-layout/iron-flex-layout-classes.html","9318625d0ab7324a70f521c7f7a364d9"],["/bower_components/iron-flex-layout/iron-flex-layout.html","31abc906fe092d26e37933efd43d7977"],["/bower_components/iron-form-element-behavior/iron-form-element-behavior.html","8d7497a4be417b47654c0841b9e7d6e0"],["/bower_components/iron-form/iron-form.html","353035b1a530e9e807ff25670dc6e299"],["/bower_components/iron-icon/iron-icon.html","031e9e342a0ef460b505bd1601ce84b3"],["/bower_components/iron-icons/av-icons.html","9926bdf47fe074657acf2e8b3822f1ad"],["/bower_components/iron-icons/iron-icons.html","263c425f0e794d1e2fd636f8039a8586"],["/bower_components/iron-icons/notification-icons.html","e586f5b5dc1b292813a0fdf80d7a5a1a"],["/bower_components/iron-iconset-svg/iron-iconset-svg.html","45659f2a02d57dcbdc5aea1226356cb2"],["/bower_components/iron-image/iron-image.html","ab10d1a13d928eca465bae74b46a5793"],["/bower_components/iron-input/iron-input.html","15ccec31ddbeb14a7df38ff98fd9b521"],["/bower_components/iron-media-query/iron-media-query.html","cf156c37b06b70f0368b23253d363414"],["/bower_components/iron-menu-behavior/iron-menu-behavior.html","0db219159a213f83b6022553e71502c2"],["/bower_components/iron-menu-behavior/iron-menubar-behavior.html","5c6662113952baa77fb0f5093136abbb"],["/bower_components/iron-meta/iron-meta.html","f4eb5d118ae903e204e7e9102ddbc137"],["/bower_components/iron-overlay-behavior/iron-focusables-helper.html","8e18f1dc70b24ce58f8eb14778086705"],["/bower_components/iron-overlay-behavior/iron-overlay-backdrop.html","6840723d9a794823ce80cba633e4096a"],["/bower_components/iron-overlay-behavior/iron-overlay-behavior.html","d69c36fe07fae9d0fd6aceb8a324f980"],["/bower_components/iron-overlay-behavior/iron-overlay-manager.html","b36b8b9fdae9dbb438dd29cb62053251"],["/bower_components/iron-resizable-behavior/iron-resizable-behavior.html","fb6d2dd64df1eb6a6882cb0a38b640f5"],["/bower_components/iron-scroll-target-behavior/iron-scroll-target-behavior.html","9439a886574f3a31fdf1a01cb3ee006d"],["/bower_components/iron-selector/iron-multi-selectable.html","049cd8e7cdea162789d84a47dc39935e"],["/bower_components/iron-selector/iron-selectable.html","3cc68433bfd2b04a446004f9d9dd1521"],["/bower_components/iron-selector/iron-selection.html","6820931a3f3849002e7a95cabd6d23f5"],["/bower_components/iron-validatable-behavior/iron-validatable-behavior.html","279eb42bc391d30feb8924eb1f2a044b"],["/bower_components/neon-animation/animations/fade-in-animation.html","d0b4ce38f6754dbd7fcecb3595d4bd20"],["/bower_components/neon-animation/animations/fade-out-animation.html","ebe3aa44b296583f5fa8e126fbacb571"],["/bower_components/neon-animation/neon-animatable-behavior.html","05b7fd53f09eb308f8167fdc4d531338"],["/bower_components/neon-animation/neon-animation-behavior.html","e16a573f699a613b2c7ce5d692f357f6"],["/bower_components/neon-animation/neon-animation-runner-behavior.html","34c79b7256414aa336768c4099b7382c"],["/bower_components/paper-behaviors/paper-button-behavior.html","1e11f79c55267e65501d85ddcd372f39"],["/bower_components/paper-behaviors/paper-checked-element-behavior.html","c21b300f19f55e621ecb82953a08ac4f"],["/bower_components/paper-behaviors/paper-inky-focus-behavior.html","5e34513d00a9b66055202e85990c1feb"],["/bower_components/paper-behaviors/paper-ripple-behavior.html","99bf6252e996b9400187621a9764d5d8"],["/bower_components/paper-button/paper-button.html","e51b4dab06e397c5ccd5a28a99b68348"],["/bower_components/paper-card/paper-card.html","b7c2971ac1711a8c4c605601851d191b"],["/bower_components/paper-checkbox/paper-checkbox.html","fd9c2e4f2201fe65adfe7b28445b2af5"],["/bower_components/paper-dialog-behavior/paper-dialog-behavior.html","e9833679ad99d02cbb4dc5386df16d33"],["/bower_components/paper-dialog-behavior/paper-dialog-shared-styles.html","b29868eb0a17b5a571683a381238ae15"],["/bower_components/paper-dialog/paper-dialog.html","c8e2516f15a9e6dc6462b46a0a22f895"],["/bower_components/paper-dropdown-menu/paper-dropdown-menu-icons.html","f683c1089dfe60d79ebbdf072c551e21"],["/bower_components/paper-dropdown-menu/paper-dropdown-menu-light.html","616366eef023fd8072bdc23fb4a86bc8"],["/bower_components/paper-dropdown-menu/paper-dropdown-menu-shared-styles.html","13493f2131c99c9d844d543469b83f0b"],["/bower_components/paper-dropdown-menu/paper-dropdown-menu.html","87c22201135641f6fe88c46aa8651880"],["/bower_components/paper-fab/paper-fab.html","a84d7971b75ad4b49db3a109f0b36041"],["/bower_components/paper-icon-button/paper-icon-button.html","83556c8d4bd16fec5b2b77aad1871124"],["/bower_components/paper-input/all-imports.html","41fc005abaabd68b324e8b275f7f852d"],["/bower_components/paper-input/paper-input-addon-behavior.html","c16915ea448c062cd51138ca7edc3f98"],["/bower_components/paper-input/paper-input-behavior.html","1afd0074b2c44cf3f9f6fb0f67fc16d9"],["/bower_components/paper-input/paper-input-char-counter.html","a905d40d32b93e3bd0fdde6e8cf4d576"],["/bower_components/paper-input/paper-input-container.html","4f5128db6338bb8445741637a6de7bd8"],["/bower_components/paper-input/paper-input-error.html","8fb3de567d045189f12dcf1397043c4c"],["/bower_components/paper-input/paper-input.html","551830431759e179b268b53acec58c73"],["/bower_components/paper-input/paper-textarea.html","921cf63a1a6d48dd92299907ce076cc5"],["/bower_components/paper-item/all-imports.html","db0d0fcce82b933130c83af24155bcb5"],["/bower_components/paper-item/paper-icon-item.html","cbf7e46d3cb65e0584855f2c090a8383"],["/bower_components/paper-item/paper-item-behavior.html","b8600d86cfee2b34340767a8a89efbfa"],["/bower_components/paper-item/paper-item-body.html","b3c26a8675426c4406eb6533d02c1e5c"],["/bower_components/paper-item/paper-item-shared-styles.html","b351fc5b330b717648c89aa1d65dea4c"],["/bower_components/paper-item/paper-item.html","159b2641089c168b41e53bdc6396120e"],["/bower_components/paper-listbox/paper-listbox.html","5d98730b8b190d041cb9bacfa8d59c55"],["/bower_components/paper-material/paper-material-shared-styles.html","832426d87cf060e721562db51fba3ed5"],["/bower_components/paper-material/paper-material.html","ecab2d62cfcebb077a223f0ebc840c2f"],["/bower_components/paper-menu-button/paper-menu-button-animations.html","8f78ea323493b863cee9760507dccc14"],["/bower_components/paper-menu-button/paper-menu-button.html","dd286857ad6006f5f96609ca2c5078aa"],["/bower_components/paper-ripple/paper-ripple.html","58b8bccadec40edf1504e9ed5062b4bc"],["/bower_components/paper-styles/classes/shadow.html","5f54b2a32b36cb0344a65bb21a01ff1b"],["/bower_components/paper-styles/classes/typography.html","9d575b5cfbafd614ef001f7ed38cd513"],["/bower_components/paper-styles/color.html","e3e3c43a7fa75c3a2f8a395ae8fd490d"],["/bower_components/paper-styles/default-theme.html","ed4df18f1171d7793508d645054335b8"],["/bower_components/paper-styles/element-styles/paper-material.html","f0f83e3976975d607e326f44e83d1217"],["/bower_components/paper-styles/paper-styles-classes.html","a07f15af4cad113457b8ca0d148e1f3e"],["/bower_components/paper-styles/paper-styles.html","8d35c422c5a451cc2e103bc898394c2a"],["/bower_components/paper-styles/shadow.html","4123860d1a9035b047714385f21f368f"],["/bower_components/paper-styles/typography.html","77efb9baab386e7f4a2807e6c2ef7f8c"],["/bower_components/paper-tabs/paper-tab.html","bd0814cbc0b839b33322621d6c4b1248"],["/bower_components/paper-tabs/paper-tabs-icons.html","c48ea33d583e13726e490f48c721bfa4"],["/bower_components/paper-tabs/paper-tabs.html","02100ada7778b43f7cad5a97cd916ccc"],["/bower_components/paper-toggle-button/paper-toggle-button.html","319985295b5cafb6ae072caf9f687795"],["/bower_components/paper-tooltip/paper-tooltip.html","7849006ee5d31c315e6aae41eca9b733"],["/bower_components/polymer/lib/elements/array-selector.html","a533713221ce907deb20accfcf043cf7"],["/bower_components/polymer/lib/elements/custom-style.html","329a70151202e92d1a775c9ecbb05020"],["/bower_components/polymer/lib/elements/dom-bind.html","35d7de5fa58f24d1c1398cec53965831"],["/bower_components/polymer/lib/elements/dom-if.html","92bce9d1c913f4d0a3b5a58deaba1e56"],["/bower_components/polymer/lib/elements/dom-module.html","eafbfc1fbd56546046f9beced1602c0f"],["/bower_components/polymer/lib/elements/dom-repeat.html","27df6872e0b6b37d8b0e9292e541928f"],["/bower_components/polymer/lib/legacy/class.html","4411e7f1c7516ef356a2dff1b78e133e"],["/bower_components/polymer/lib/legacy/legacy-element-mixin.html","2fd018c0c997e91be7fb56fc29a5360f"],["/bower_components/polymer/lib/legacy/mutable-data-behavior.html","d2e60534a0807f221ca8319102b2b241"],["/bower_components/polymer/lib/legacy/polymer-fn.html","508de8f9a33aae2d161266109d6ce46f"],["/bower_components/polymer/lib/legacy/polymer.dom.html","c3d527c113f2fc5d8f04cbd5a91c3179"],["/bower_components/polymer/lib/legacy/templatizer-behavior.html","9b5b00c916b0aa0c5ac5d2413934c27b"],["/bower_components/polymer/lib/mixins/element-mixin.html","1058ff096ab071407dcb32334baaa343"],["/bower_components/polymer/lib/mixins/gesture-event-listeners.html","5f4b8db08fcb111f0ed67c5f97f4539e"],["/bower_components/polymer/lib/mixins/mutable-data.html","053a0eecf5747997cf45ef2781954701"],["/bower_components/polymer/lib/mixins/property-accessors.html","0bbcf95306087e34914e7dcd89188655"],["/bower_components/polymer/lib/mixins/property-effects.html","93795d20cccf99209eb2e37d3e8a26d3"],["/bower_components/polymer/lib/mixins/template-stamp.html","c4478d12027c6b0ecee1d09315e947dc"],["/bower_components/polymer/lib/utils/array-splice.html","9e68161820af288f38b3635b8af8a72f"],["/bower_components/polymer/lib/utils/async.html","6bc19f31af768d0206454fa29b5c3de9"],["/bower_components/polymer/lib/utils/boot.html","0b537486c076290de61a3e0ac9cdadd4"],["/bower_components/polymer/lib/utils/case-map.html","7bded4d7af1b3e7cbb32862a6e3862d8"],["/bower_components/polymer/lib/utils/debounce.html","055d03d79237bdf56b1b93eca531d2e2"],["/bower_components/polymer/lib/utils/flattened-nodes-observer.html","e972eb27950afb8bccaa339072c39466"],["/bower_components/polymer/lib/utils/flush.html","d4e23bab0328b6319f7cf9a41feea5d7"],["/bower_components/polymer/lib/utils/gestures.html","caec0d157ef554d5ad8fc943b9840bf1"],["/bower_components/polymer/lib/utils/import-href.html","f91aca107259bb85b45d053037fa2f30"],["/bower_components/polymer/lib/utils/mixin.html","02108334150b9134f5e49c0147b2b199"],["/bower_components/polymer/lib/utils/path.html","9505ee952fbf33aae20fdd103b452cff"],["/bower_components/polymer/lib/utils/render-status.html","0bdd1fb68faf99af5eef507c44496e8e"],["/bower_components/polymer/lib/utils/resolve-url.html","0b29bf2e3cf6ff4de0c67b4dd5f29185"],["/bower_components/polymer/lib/utils/style-gather.html","87da74d1a90bc20a05d296ae845a4396"],["/bower_components/polymer/lib/utils/templatize.html","98b72b58246a47c43a379f918cbe332c"],["/bower_components/polymer/lib/utils/unresolved.html","91b0d5a50989cdeddd3481eddefc3919"],["/bower_components/polymer/polymer-element.html","39275b896623fee1e7e694f2c8fd3773"],["/bower_components/polymer/polymer.html","564b54a6e1b1b5eebcb43ad4c850dab5"],["/bower_components/shadycss/apply-shim.html","a7855a6be7cd2ceab940f13c1afba1f3"],["/bower_components/shadycss/apply-shim.min.js","64dd71c4e36f0b394ea8b6a7048a6ea6"],["/bower_components/shadycss/custom-style-interface.html","7784f566f143bec28bf67b864bedf658"],["/bower_components/shadycss/custom-style-interface.min.js","4fe6823d0e0000d4f57dce7e12b9fccf"],["/bower_components/web-animations-js/web-animations-next.min.html","d452c4110bc11a8c8e2b64642f2fe5f7"],["/bower_components/web-animations-js/web-animations-next.min.js","549d5dff627149e44eff374700074d73"],["/common.js","b7ec4e9616f2d225cf59a02374c64661"],["/favicon.ico","17b48e461e0c4fd7cc5c0cd2ba1dc3c4"],["/imports.html","4bba209e110341698490ad498cc05d9e"],["/index.html","7b5f25c5ee47a6ff3628c53d0a60a466"],["/main.js","4d00641625156d1829c2af29790da93a"],["/manifest.json","1cf64a8dfdab51bfe44fafc7b6a1cb26"],["/stack.png","3d665038e72997c9d40f2f77fa08e9a7"]];
var cacheName = 'sw-precache-v2--' + (self.registration ? self.registration.scope : '');


var ignoreUrlParametersMatching = [/^utm_/];



var addDirectoryIndex = function (originalUrl, index) {
    var url = new URL(originalUrl);
    if (url.pathname.slice(-1) === '/') {
      url.pathname += index;
    }
    return url.toString();
  };

var createCacheKey = function (originalUrl, paramName, paramValue,
                           dontCacheBustUrlsMatching) {
    // Create a new URL object to avoid modifying originalUrl.
    var url = new URL(originalUrl);

    // If dontCacheBustUrlsMatching is not set, or if we don't have a match,
    // then add in the extra cache-busting URL parameter.
    if (!dontCacheBustUrlsMatching ||
        !(url.toString().match(dontCacheBustUrlsMatching))) {
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
              return cache.add(new Request(cacheKey, {
                credentials: 'same-origin',
                redirect: 'follow'
              }));
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

    // First, remove all the ignored parameter and see if we have that URL
    // in our cache. If so, great! shouldRespond will be true.
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

