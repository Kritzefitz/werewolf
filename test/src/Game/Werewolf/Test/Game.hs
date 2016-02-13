{-|
Module      : Game.Werewolf.Test.Game
Copyright   : (c) Henry J. Wylde, 2015
License     : BSD3
Maintainer  : public@hjwylde.com
-}

{-# OPTIONS_HADDOCK hide, prune #-}

module Game.Werewolf.Test.Game (
    prop_newGameStartsWithSunsetStage, prop_newGameStartsOnFirstRound,
    prop_newGameStartsWithEventsEmpty, prop_newGameStartsWithPassesEmpty,
    prop_newGameStartsWithNoHeal, prop_newGameStartsWithNoHealUsed, prop_newGameStartsWithNoPoison,
    prop_newGameStartsWithNoPoisonUsed, prop_newGameStartsWithNoPriorProtect,
    prop_newGameStartsWithNoProtect, prop_newGameStartsWithNoSee,
    prop_newGameStartsWithVotesEmpty, prop_newGameUsesGivenPlayers,
) where

import Control.Lens

import qualified Data.Map   as Map
import           Data.Maybe

import Game.Werewolf.Game
import Game.Werewolf.Player

import Prelude hiding (round)

prop_newGameStartsWithSunsetStage :: [Player] -> Bool
prop_newGameStartsWithSunsetStage players = isSunset (newGame players)

prop_newGameStartsOnFirstRound :: [Player] -> Bool
prop_newGameStartsOnFirstRound players = isFirstRound $ newGame players

prop_newGameStartsWithEventsEmpty :: [Player] -> Bool
prop_newGameStartsWithEventsEmpty players = null $ newGame players ^. events

prop_newGameStartsWithPassesEmpty :: [Player] -> Bool
prop_newGameStartsWithPassesEmpty players = null $ newGame players ^. passes

prop_newGameStartsWithNoHeal :: [Player] -> Bool
prop_newGameStartsWithNoHeal players = not $ newGame players ^. heal

prop_newGameStartsWithNoHealUsed :: [Player] -> Bool
prop_newGameStartsWithNoHealUsed players = not $ newGame players ^. healUsed

prop_newGameStartsWithNoPoison :: [Player] -> Bool
prop_newGameStartsWithNoPoison players = isNothing $ newGame players ^. poison

prop_newGameStartsWithNoPoisonUsed :: [Player] -> Bool
prop_newGameStartsWithNoPoisonUsed players = not $ newGame players ^. poisonUsed

prop_newGameStartsWithNoPriorProtect :: [Player] -> Bool
prop_newGameStartsWithNoPriorProtect players = isNothing $ newGame players ^. priorProtect

prop_newGameStartsWithNoProtect :: [Player] -> Bool
prop_newGameStartsWithNoProtect players = isNothing $ newGame players ^. protect

prop_newGameStartsWithNoSee :: [Player] -> Bool
prop_newGameStartsWithNoSee players = isNothing $ newGame players ^. see

prop_newGameStartsWithVotesEmpty :: [Player] -> Bool
prop_newGameStartsWithVotesEmpty players = Map.null $ newGame players ^. votes

prop_newGameUsesGivenPlayers :: [Player] -> Bool
prop_newGameUsesGivenPlayers players' = newGame players' ^. players == players'
