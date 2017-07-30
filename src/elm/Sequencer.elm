module Sequencer exposing (..)

import List.Extra as List
import Maybe.Extra as Maybe
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)


_ =
    1



--type alias SequencerModel msg =
--    { list : List msg
--    }
--
--
--sequencerInitialValue : SequencerModel msg
--sequencerInitialValue =
--    { list = [] }
--
--
--sequencerAppendToSequence msg =
--    \model -> { model | list = model.list ++ [ msg ] }
--
--
--sequencerProcessSequence : ReturnF msg (SequencerModel msg)
--sequencerProcessSequence =
--    returnWithMaybe1 (.list >> List.head) returnMsgAsCmd
--        >> map (\model -> { model | list = List.drop 1 model.list })
--    , sequencer : SequencerModel AppMsg
--sequencer =
--    fieldLens .sequencer (\s b -> { b | sequencer = s })
--appendToSequence msg =
--    map (over sequencer (sequencerAppendToSequence msg))
--        >> overReturnF sequencer sequencerProcessSequence
