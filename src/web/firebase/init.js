import firebase from "firebase"
import Kefir from "kefir"

const firebaseConfig = (() => {
    //noinspection JSUnresolvedVariable
    if (IS_DEVELOPMENT_ENV) {
      return {
        apiKey: "AIzaSyASFVPlWjIrpgSlmlEEIMZ0dtPFOuRC0Hc",
        authDomain: "rational-mote-664.firebaseapp.com",
        databaseURL: "https://rational-mote-664.firebaseio.com",
        projectId: "rational-mote-664",
        storageBucket: "rational-mote-664.appspot.com",
        messagingSenderId: "49437522774",
      }
    } else {
      return {
        apiKey: "AIzaSyDgqOiOMuTvK3PdzJ0Oz6ctEg-devcgZYc",
        authDomain: "simple-gtd-prod.firebaseapp.com",
        databaseURL: "https://simple-gtd-prod.firebaseio.com",
        projectId: "simple-gtd-prod",
        storageBucket: "simple-gtd-prod.appspot.com",
        messagingSenderId: "1061254169900",
      }
    }
  }
)()

firebase.initializeApp(firebaseConfig);

export default {

  onAuthStateChanged(){

    const stream = Kefir.stream(emitter => {
      firebase.auth().onAuthStateChanged(user => {
        emitter.emit(user)
      })
    })
    stream.observe({error(error){console.error(error)}})
    return stream

  },
}
