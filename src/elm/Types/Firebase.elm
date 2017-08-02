module Types.Firebase exposing (..)


type alias FirebaseModel =
    { maybeUser : MaybeUser
    , fcmToken : FCMToken
    , firebaseClient : FirebaseClient
    , showSignInDialog : Bool
    }


type alias MaybeUser =
    Maybe User


type alias User =
    { id : String
    , providerData : List Provider
    }


type alias Provider =
    { displayName : String
    , email : String
    , photoURL : String
    , providerId : String
    , uid : String
    }


type alias FCMToken =
    Maybe String


type alias FirebaseClient =
    { id : DeviceId
    , connected : Bool
    , token : Maybe String
    }


type alias DeviceId =
    String
