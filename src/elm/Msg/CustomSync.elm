module Msg.CustomSync exposing (..)

import ExclusiveMode.Types exposing (SyncForm)


type CustomSyncMsg
    = OnStartCustomSync SyncForm
    | OnUpdateCustomSyncFormUri SyncForm String
