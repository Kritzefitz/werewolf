{-|
Module      : Game.Werewolf.Role
Description : Role data structures.

Copyright   : (c) Henry J. Wylde, 2015
License     : BSD3
Maintainer  : public@hjwylde.com

Role data structures.
-}

{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}

module Game.Werewolf.Role (
    -- * Role
    Role, name, allegiance, description, advice,

    -- ** Instances
    allRoles, restrictedRoles,
    defenderRole, scapegoatRole, seerRole, simpleVillagerRole, villagerVillagerRole, werewolfRole,
    witchRole, wolfHoundRole,

    -- * Allegiance
    Allegiance(..),

    -- ** Instances
    allAllegiances,
) where

import Control.Lens

import           Data.Function
import           Data.List
import           Data.Text     (Text)
import qualified Data.Text     as T

import Prelude hiding (all)

data Role = Role
    { _name        :: Text
    , _allegiance  :: Allegiance
    , _description :: Text
    , _advice      :: Text
    } deriving (Read, Show)

data Allegiance = Villagers | Werewolves
    deriving (Eq, Read, Show)

makeLenses ''Role

instance Eq Role where
    (==) = (==) `on` view name

allRoles :: [Role]
allRoles =
    [ defenderRole
    , scapegoatRole
    , seerRole
    , simpleVillagerRole
    , villagerVillagerRole
    , werewolfRole
    , witchRole
    , wolfHoundRole
    ]

restrictedRoles :: [Role]
restrictedRoles = allRoles \\ [simpleVillagerRole, werewolfRole]

defenderRole :: Role
defenderRole = Role
    { _name         = "Defender"
    , _allegiance   = Villagers
    , _description  = T.unwords
        [ "A knight living in Miller's Hollow."
        , "The Defender has the ability to protect one player, except themself, each night."
        ]
    , _advice       =
        "Be careful when you choose to protect someone, you cannot protect them 2 nights in a row."
    }

scapegoatRole :: Role
scapegoatRole = Role
    { _name         = "Scapegoat"
    , _allegiance   = Villagers
    , _description  = "That one person everyone loves to blame."
    , _advice       = "Cross your fingers that the votes don't end up tied."
    }

seerRole :: Role
seerRole = Role
    { _name         = "Seer"
    , _allegiance   = Villagers
    , _description  = T.unwords
        [ "A fortunate teller by other names, with the ability to see into fellow"
        , "townsfolk and determine their allegiance."
        ]
    , _advice       = T.unwords
        [ "Be extremely careful if you have discovered a Werewolf."
        , "It may be worth the pain of revealing yourself in order to identify the player,"
        , "but avoid doing this too early."
        ]
    }

simpleVillagerRole :: Role
simpleVillagerRole = Role
    { _name         = "Simple Villager"
    , _allegiance   = Villagers
    , _description  = "An ordinary townsperson humbly living in Millers Hollow."
    , _advice       =
        "Bluffing can be a good technique, but you had better be convincing about what you say."
    }

villagerVillagerRole :: Role
villagerVillagerRole = Role
    { _name         = "Villager-Villager"
    , _allegiance   = Villagers
    , _description  = "An honest townsperson humbly living in Millers Hollow."
    , _advice       = "You'll make friends quickly, but be wary about whom you trust."
    }

werewolfRole :: Role
werewolfRole = Role
    { _name         = "Werewolf"
    , _allegiance   = Werewolves
    , _description  =
        "A shapeshifting townsperson that, at night, hunts the residents of Millers Hollow."
    , _advice       =
        "Voting against your partner can be a good way to deflect suspicion from yourself."
    }

witchRole :: Role
witchRole = Role
    { _name         = "Witch"
    , _allegiance   = Villagers
    , _description  = T.unwords
        [ "A conniving townsperson."
        , "She knows how to make up 2 extremely powerful potions;"
        , "one healing potion which can revive the Werewolves' victim,"
        , "one poison potion which when used can kill a player."
        ]
    , _advice       = T.unwords
        [ "Each potion may only be used once per game,"
        , "but there are no restrictions on using both on one night."
        ]
    }

wolfHoundRole :: Role
wolfHoundRole = Role
    { _name         = "Wolf-hound"
    , _allegiance   = Villagers
    , _description  = T.unwords
        [ "All dogs know in the depths of their soul that their acestors were wolves"
        , "and that it's Mankind who has kept them in the state of childishness and fear,"
        , "the faithful and generous companions."
        , "In any case, only the Wolf-hound can decide if he'll obey his human and civilized master"
        , "or if he'll listen to the call of wild nature buried within him."
        ]
    , _advice       =
        "The choice of being a Simple Villager or Werewolf is final, so decide carefully!"
    }

allAllegiances :: [Allegiance]
allAllegiances = [Villagers, Werewolves]
