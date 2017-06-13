module Todo.Schedule exposing (..)

import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


type alias Model =
    Schedule


type Schedule
    = NoReminder Time
    | WithReminder Time Time
    | Unscheduled


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
