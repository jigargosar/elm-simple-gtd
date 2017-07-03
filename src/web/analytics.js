// //@formatter:off
// (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
//         (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
//     m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
// })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');
// //@formatter:on
//
//
// ga('create', 'UA-349746-5', 'auto')
// ga('send', 'pageview')

import F from "./firebase/init.js"
// import _ from "ramda"
import Cookies from "browser-cookies"


F.onAuthStateChanged()
 // .filter(_.compose(_.not, _.isNil))
 .observe({
   value: user => {

     console.log("onAuthStateChanged", !!user)

     if (user) {
       Cookies.set("firebase_uid", user.uid, {expires: 30})
     } else {
       Cookies.erase("firebase_uid")
     }

     // return window.ga('set', 'userId', user.uid)

   },
 })


