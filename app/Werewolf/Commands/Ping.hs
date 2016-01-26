{-|
Module      : Werewolf.Commands.Ping
Description : Handler for the ping subcommand.

Copyright   : (c) Henry J. Wylde, 2015
License     : BSD3
Maintainer  : public@hjwylde.com

Handler for the ping subcommand.
-}

{-# LANGUAGE OverloadedStrings #-}

module Werewolf.Commands.Ping (
    -- * Handle
    handle,
) where

import Control.Monad.Except
import Control.Monad.Extra
import Control.Monad.State
import Control.Monad.Writer

import Data.Text (Text)

import Game.Werewolf.Command
import Game.Werewolf.Engine
import Game.Werewolf.Response

-- | Handle.
handle :: MonadIO m => Text -> m ()
handle callerName = do
    unlessM doesGameExist $ exitWith failure {
        messages = [privateMessage [callerName] "No game is running."]
        }

    game <- readGame

    let command = pingCommand

    case runExcept (execWriterT $ execStateT (apply command) game) of
        Left errorMessages  -> exitWith failure { messages = errorMessages }
        Right messages      -> exitWith success { messages = messages }
