{-|
Module      : Werewolf.Command.Status
Description : Handler for the status subcommand.

Copyright   : (c) Henry J. Wylde, 2016
License     : BSD3
Maintainer  : public@hjwylde.com

Handler for the status subcommand.
-}

module Werewolf.Command.Status (
    -- * Handle
    handle,
) where

import Control.Monad.Except
import Control.Monad.Extra
import Control.Monad.State
import Control.Monad.Writer

import Data.Text (Text)

import Game.Werewolf
import Game.Werewolf.Command
import Game.Werewolf.Command.Status
import Game.Werewolf.Message.Error

import Werewolf.System

handle :: MonadIO m => Text -> Text -> m ()
handle callerName tag = do
    unlessM (doesGameExist tag) $ exitWith failure
        { messages = [noGameRunningMessage callerName]
        }

    game <- readGame tag

    let command = statusCommand callerName

    case runExcept . execWriterT $ execStateT (apply command) game of
        Left errorMessages  -> exitWith failure { messages = errorMessages }
        Right messages      -> exitWith success { messages = messages }
