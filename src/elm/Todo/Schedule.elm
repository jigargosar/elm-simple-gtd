module Todo.Schedule exposing (..)

import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E


type alias Model =
    Schedule


type Schedule
    = NoReminder Time
    | WithReminder Time Time
    | Unscheduled


decode : Decoder Model
decode =
    D.oneOf
        [ decodeV2
        , decodeV1
        , D.succeed unscheduled
        ]


encode model =
    let
        encodeDueAt dueAt =
            "dueAt" => E.float dueAt

        fields =
            case model of
                NoReminder dueAt ->
                    [ encodeDueAt dueAt ]

                WithReminder dueAt reminderAt ->
                    [ encodeDueAt dueAt
                    , "reminderAt" => E.float reminderAt
                    ]

                Unscheduled ->
                    []
    in
        E.object fields


decodeV2 : Decoder Model
decodeV2 =
    let
        decodeWithDueAt dueAt =
            D.oneOf
                [ D.at [ "schedule", "reminderAt" ] D.float
                    |> D.andThen
                        (\reminderAt ->
                            initWithDueAtAndReminder dueAt reminderAt
                                |> D.succeed
                        )
                , initWithDueAt dueAt |> D.succeed
                ]
    in
        D.at [ "schedule", "dueAt" ] D.float
            |> D.andThen decodeWithDueAt


decodeV1 : Decoder Model
decodeV1 =
    let
        decodeWithDueAt dueAt =
            D.oneOf
                [ D.at [ "reminder", "at" ] D.float
                    |> D.andThen
                        (\reminder ->
                            initWithDueAtAndReminder dueAt reminder
                                |> D.succeed
                        )
                , D.succeed (initWithDueAt dueAt)
                ]
    in
        D.field "dueAt" D.float
            |> D.andThen decodeWithDueAt


initWithReminder time =
    WithReminder time time


initWithDueAtAndReminder dueAt reminder =
    WithReminder dueAt reminder


initWithDueAt dueAt =
    NoReminder dueAt


unscheduled =
    Unscheduled


getMaybeDueAt model =
    case model of
        NoReminder dueAt ->
            Just dueAt

        WithReminder dueAt _ ->
            Just dueAt

        Unscheduled ->
            Nothing


getMaybeReminderTime model =
    case model of
        NoReminder dueAt ->
            Nothing

        WithReminder _ reminderTime ->
            Just reminderTime

        Unscheduled ->
            Nothing


fromMaybeTime maybeTime =
    maybeTime
        ?|> initWithReminder
        ?= unscheduled


turnReminderOff model =
    case model of
        WithReminder dueAt _ ->
            NoReminder dueAt

        NoReminder dueAt ->
            model

        Unscheduled ->
            model


autoSnooze now =
    snoozeTill (now + (Time.minute * 15))


snoozeTill snoozedTillTime model =
    case model of
        NoReminder dueAt ->
            WithReminder dueAt snoozedTillTime

        WithReminder dueAt _ ->
            WithReminder dueAt snoozedTillTime

        Unscheduled ->
            model


hasReminderChanged old new =
    (getMaybeReminderTime old) /= (getMaybeReminderTime new)
