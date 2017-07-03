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


