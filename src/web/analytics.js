import F from "./firebase/init.js"
import Cookies from "browser-cookies"
import $ from "jquery"

F.onAuthStateChanged()
 .observe({
   value: user => {

     console.log("onAuthStateChanged", !!user)

     if (user) {
       Cookies.set("firebase_uid", user.uid, {expires: 30})
     } else {
       Cookies.erase("firebase_uid")
     }
   },
 })

global.getClosestAttribute = (element, attrName) =>{
  return $(element).closest(`[${attrName}]`).attr(attrName)
}
