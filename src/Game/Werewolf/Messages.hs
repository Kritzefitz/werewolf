{-|
Module      : Game.Werewolf.Messages
Description : Suite of messages used throughout the game.

Copyright   : (c) Henry J. Wylde, 2016
License     : BSD3
Maintainer  : public@hjwylde.com

A 'Message' is used to relay information back to either all players or a single player. This module
defines suite of messages used throughout the werewolf game, including both game play messages and
binary errors.

@werewolf@ was designed to be ambivalent to the playing chat client. The response-message structure
reflects this by staying away from anything that could be construed as client-specific. This
includes features such as emoji support.
-}

{-# LANGUAGE OverloadedStrings #-}

module Game.Werewolf.Messages (
    -- * Generic messages
    newGameMessages, stageMessages, gameOverMessages, playerQuitMessage, gameIsOverMessage,

    -- ** Error messages
    playerDoesNotExistMessage, playerCannotDoThatMessage, playerCannotDoThatRightNowMessage,
    playerIsDeadMessage, targetIsDeadMessage,

    -- * Boot messages
    playerVotedToBootMessage, playerBootedMessage,

    -- ** Error messages
    playerHasAlreadyVotedToBootMessage,

    -- * Circle messages
    circleMessage,

    -- * Ping messages
    pingPlayerMessage, pingRoleMessage,

    -- * Status messages
    currentStageMessages, rolesInGameMessage, playersInGameMessage, waitingOnMessage,

    -- * Angel's turn messages
    angelJoinedVillagersMessage,

    -- * Devoted Servant's turn messages
    devotedServantRevealedMessage, devotedServantJoinedPackMessages,

    -- * Druid's turn messages
    ferinaGruntsMessage,

    -- * Protector's turn messages

    -- ** Error messages
    playerCannotProtectSamePlayerTwiceInARowMessage,

    -- * Scapegoat's turn messages
    scapegoatChoseAllowedVotersMessage,

    -- ** Error messages
    playerMustChooseAtLeastOneTargetMessage, playerCannotChooseJesterMessage,

    -- * Seer's turn messages
    playerSeenMessage,

    -- * Villages' turn messages
    playerMadeLynchVoteMessage, playerLynchedMessage, noPlayerLynchedMessage,
    jesterLynchedMessage, scapegoatLynchedMessage,

    -- ** Error messages
    playerHasAlreadyVotedMessage,

    -- * Werewolves' turn messages
    playerMadeDevourVoteMessage, playerDevouredMessage, noPlayerDevouredMessage,

    -- ** Error messages
    playerCannotDevourAnotherWerewolfMessage,

    -- * Wild-child's turn messages
    wildChildJoinedPackMessages,

    -- ** Error messages
    playerCannotChooseSelfMessage,

    -- * Witch's turn messages
    playerPoisonedMessage,

    -- ** Error messages
    playerHasAlreadyHealedMessage, playerHasAlreadyPoisonedMessage,

    -- * Wolf-hound's turn messages

    -- ** Error messages
    allegianceDoesNotExistMessage,
) where

import Control.Arrow
import Control.Lens

import           Data.List.Extra
import           Data.Text       (Text)
import qualified Data.Text       as T

import           Game.Werewolf.Game
import           Game.Werewolf.Player
import           Game.Werewolf.Response
import           Game.Werewolf.Role     hiding (name)
import qualified Game.Werewolf.Role     as Role

newGameMessages :: Game -> [Message]
newGameMessages game = concat
    [ [newPlayersInGameMessage $ players' ^.. names]
    , [rolesInGameMessage Nothing $ players' ^.. roles]
    , map newPlayerMessage players'
    , villagerVillagerMessages
    , stageMessages game
    ]
    where
        players'                    = game ^. players
        villagerVillagerMessages    = case players' ^? villagerVillagers of
            Just villagerVillager   -> [villagerVillagerMessage $ villagerVillager ^. name]
            _                       -> []

newPlayersInGameMessage :: [Text] -> Message
newPlayersInGameMessage playerNames = publicMessage $ T.concat
    [ "A new game of werewolf is starting with "
    , T.intercalate ", " playerNames, "!"
    ]

newPlayerMessage :: Player -> Message
newPlayerMessage player = privateMessage (player ^. name) $ T.intercalate "\n"
    [ T.concat ["You're ", article playerRole, " ", playerRole ^. Role.name, "."]
    , playerRole ^. description
    , playerRole ^. rules
    ]
    where
        playerRole = player ^. role

villagerVillagerMessage :: Text -> Message
villagerVillagerMessage name = publicMessage $ T.unwords
    [ "Unguarded advice is seldom given, for advice is a dangerous gift,"
    , "even from the wise to the wise, and all courses may run ill."
    , "Yet as you feel like you need help, I begrudgingly leave you with this:"
    , name, "is the Villager-Villager."
    ]

stageMessages :: Game -> [Message]
stageMessages game = case game ^. stage of
    DevotedServantsTurn -> devotedServantsTurnMessages devotedServantsName victimsName
    FerinasGrunt        -> []
    GameOver            -> []
    Lynching            -> []
    ProtectorsTurn      -> protectorsTurnMessages protectorsName
    ScapegoatsTurn      -> scapegoatsTurnMessages scapegoatsName
    SeersTurn           -> seersTurnMessages seersName
    Sunrise             -> [sunriseMessage]
    Sunset              -> [nightFallsMessage]
    VillagesTurn        -> if isFirstRound game
        then firstVillagesTurnMessages
        else villagesTurnMessages
    WerewolvesTurn      -> if isFirstRound game
        then firstWerewolvesTurnMessages aliveWerewolfNames
        else werewolvesTurnMessages aliveWerewolfNames
    WildChildsTurn      -> wildChildsTurnMessages wildChildsName
    WitchsTurn          -> witchsTurnMessages game
    WolfHoundsTurn      -> wolfHoundsTurnMessages wolfHoundsName
    where
        players'            = game ^. players
        protectorsName      = players' ^?! protectors . name
        devotedServantsName = players' ^?! devotedServants . name
        victimsName         = head (getVoteResult game) ^. name
        scapegoatsName      = players' ^?! scapegoats . name
        seersName           = players' ^?! seers . name
        aliveWerewolfNames  = players' ^.. werewolves . alive . name
        wildChildsName      = players' ^?! wildChildren . name
        wolfHoundsName      = players' ^?! wolfHounds . name

devotedServantsTurnMessages :: Text -> Text -> [Message]
devotedServantsTurnMessages to victimsName =
    [ publicMessage "The Devoted Servant ponders."
    , privateMessage to $ T.concat
        [ "Would you like to `reveal` yourself and take on ", victimsName, "'s role?"
        , " (Or you can type `pass`.)"
        ]
    ]

protectorsTurnMessages :: Text -> [Message]
protectorsTurnMessages to =
    [ publicMessage "The Protector wakes up."
    , privateMessage to "Whom would you like to `protect`?"
    ]

scapegoatsTurnMessages :: Text -> [Message]
scapegoatsTurnMessages scapegoatsName =
    [ publicMessage "Just before he burns to a complete crisp, he cries out a dying wish."
    , publicMessage $ T.concat [scapegoatsName, ", whom do you `choose` to vote on the next day?"]
    ]

seersTurnMessages :: Text -> [Message]
seersTurnMessages to =
    [ publicMessage "The Seer wakes up."
    , privateMessage to "Whose allegiance would you like to `see`?"
    ]

sunriseMessage :: Message
sunriseMessage = publicMessage "The sun rises. Everybody wakes up and opens their eyes..."

nightFallsMessage :: Message
nightFallsMessage = publicMessage "Night falls, the village is asleep."

firstVillagesTurnMessages :: [Message]
firstVillagesTurnMessages = angelInPlayMessage : villagesTurnMessages
    where
        angelInPlayMessage = publicMessage $ T.unwords
            [ "Alas, again I regrettably yield advice: an angelic menace walks among you."
            , "Do not cast your votes lightly,"
            , "for he will relish in this opportunity to be free from his terrible nightmare."
            ]

villagesTurnMessages :: [Message]
villagesTurnMessages =
    [ publicMessage "As the village gathers in the square the town clerk calls for a vote."
    , publicMessage "Whom would you like to `vote` to lynch?"
    ]

firstWerewolvesTurnMessages :: [Text] -> [Message]
firstWerewolvesTurnMessages tos =
    [privateMessage to $ packMessage to | length tos > 1, to <- tos]
    ++ werewolvesTurnMessages tos
    where
        packMessage werewolfName    = T.unwords
            [ "You feel restless, like an old curse is keeping you from sleep."
            , "It seems you're not the only one..."
            , packNames werewolfName
            , if length tos == 2 then "is" else "are", "also emerging from their"
            , if length tos == 2 then "home." else "homes."
            ]
        packNames werewolfName      = T.intercalate ", " (tos \\ [werewolfName])

werewolvesTurnMessages :: [Text] -> [Message]
werewolvesTurnMessages tos =
    publicMessage "The Werewolves wake up, transform and choose a new victim."
    : groupMessages tos "Whom would you like to `vote` to devour?"

wildChildsTurnMessages :: Text -> [Message]
wildChildsTurnMessages to =
    [ publicMessage "The Wild-child wakes up."
    , privateMessage to "Whom do you `choose` to be your role model?"
    ]

witchsTurnMessages :: Game -> [Message]
witchsTurnMessages game = concat
    [ [wakeUpMessage]
    , devourMessages
    , healMessages
    , poisonMessages
    , [passMessage]
    ]
    where
        witchsName      = game ^?! players . witches . name
        wakeUpMessage   = publicMessage "The Witch wakes up."
        passMessage     = privateMessage witchsName "Type `pass` to end your turn."
        devourMessages  = case game ^? events . traverse . _DevourEvent of
            Just targetName ->
                [ privateMessage witchsName $
                    T.unwords ["You see", targetName, "sprawled outside bleeding uncontrollably."]
                ]
            _               -> []
        healMessages
            | not (game ^. healUsed)
                && has (events . traverse . _DevourEvent) game  = [privateMessage witchsName "Would you like to `heal` them?"]
            | otherwise                                         = []
        poisonMessages
            | not (game ^. poisonUsed) = [privateMessage witchsName "Would you like to `poison` anyone?"]
            | otherwise                = []

wolfHoundsTurnMessages :: Text -> [Message]
wolfHoundsTurnMessages to =
    [ publicMessage "The Wolf-hound wakes up."
    , privateMessage to
        "Which allegiance do you `choose` to be aligned with? (Either `villagers` or `werewolves`.)"
    ]

gameOverMessages :: Game -> [Message]
gameOverMessages game
    | hasAngelWon game      = concat
        [ [publicMessage "You should have heeded my warning, for now the Angel has been set free!"]
        , [publicMessage "The game is over! The Angel has won."]
        , [playerRolesMessage]
        , playerWonMessages
        , playerLostMessages
        ]
    | hasVillagersWon game  = concat
        [ [publicMessage "The game is over! The Villagers have won."]
        , [playerRolesMessage]
        , playerWonMessages
        , playerContributedMessages
        , playerLostMessages
        ]
    | hasWerewolvesWon game = concat
        [ [publicMessage "The game is over! The Werewolves have won."]
        , [playerRolesMessage]
        , playerWonMessages
        , playerContributedMessages
        , playerLostMessages
        ]
    | otherwise             = undefined
    where
        playerRolesMessage = publicMessage $ T.concat
            [ "As I know you're all wondering who lied to you, here's the role allocations: "
            , T.intercalate ", "
                (map
                    (\player -> T.concat [player ^. name, " (", player ^. role . Role.name, ")"])
                    (game ^. players)
                    )
            , "."
            ]

        winningAllegiance
            | hasAngelWon game      = Angel
            | hasVillagersWon game  = Villagers
            | hasWerewolvesWon game = Werewolves
            | otherwise             = undefined

        winningPlayers  = game ^.. players . traverse . filteredBy (role . allegiance) winningAllegiance
        losingPlayers   = game ^. players \\ winningPlayers

        playerWonMessages           = map playerWonMessage (winningPlayers ^.. traverse . alive . name)
        playerContributedMessages   = map playerContributedMessage (winningPlayers ^.. traverse . dead . name)
        playerLostMessages          = map playerLostMessage (losingPlayers ^.. names)

playerWonMessage :: Text -> Message
playerWonMessage to = privateMessage to "Victory! You won!"

playerContributedMessage :: Text -> Message
playerContributedMessage to = privateMessage to "Your team won, but you died. Congratulations?"

playerLostMessage :: Text -> Message
playerLostMessage to = privateMessage to "Feck, you lost this time round."

playerQuitMessage :: Player -> Message
playerQuitMessage player = publicMessage $ T.unwords [playerName, "the", playerRole, "has quit!"]
    where
        playerName = player ^. name
        playerRole = player ^. role . Role.name

gameIsOverMessage :: Text -> Message
gameIsOverMessage to = privateMessage to "The game is over!"

playerDoesNotExistMessage :: Text -> Text -> Message
playerDoesNotExistMessage to name = privateMessage to $ T.unwords ["Player", name, "does not exist."]

playerCannotDoThatMessage :: Text -> Message
playerCannotDoThatMessage to = privateMessage to "You cannot do that!"

playerCannotDoThatRightNowMessage :: Text -> Message
playerCannotDoThatRightNowMessage to = privateMessage to "You cannot do that right now!"

playerIsDeadMessage :: Text -> Message
playerIsDeadMessage to = privateMessage to "Sshh, you're meant to be dead!"

targetIsDeadMessage :: Text -> Text -> Message
targetIsDeadMessage to targetName = privateMessage to $ T.unwords [targetName, "is already dead!"]

playerVotedToBootMessage :: Text -> Text -> Message
playerVotedToBootMessage playerName targetName = publicMessage $ T.concat
    [playerName, " voted to boot ", targetName, "!"]

playerBootedMessage :: Player -> Message
playerBootedMessage player = publicMessage $ T.unwords
    [ playerName, "the", playerRole ^. Role.name
    , "has been booted from the game!"
    ]
    where
        playerName = player ^. name
        playerRole = player ^. role

playerHasAlreadyVotedToBootMessage :: Text -> Text -> Message
playerHasAlreadyVotedToBootMessage to targetName = privateMessage to $ T.concat
    ["You've already voted to boot ", targetName, "!"]

circleMessage :: Text -> [Player] -> Message
circleMessage to players = privateMessage to $ T.concat
    [ "The players are sitting in the following order:\n"
    , T.intercalate " <-> " (map playerName (players ++ [head players]))
    ]
    where
        playerName player = T.concat [player ^. name, if is dead player then " (dead)" else ""]

pingPlayerMessage :: Text -> Message
pingPlayerMessage to = privateMessage to "Waiting on you..."

pingRoleMessage :: Text -> Message
pingRoleMessage roleName = publicMessage $ T.concat ["Waiting on the ", roleName, "..."]

currentStageMessages :: Text -> Stage -> [Message]
currentStageMessages _ FerinasGrunt = []
currentStageMessages to GameOver    = [gameIsOverMessage to]
currentStageMessages _ Lynching     = []
currentStageMessages _ Sunrise      = []
currentStageMessages _ Sunset       = []
currentStageMessages to turn        = [privateMessage to $ T.concat
    [ "It's currently the ", showTurn turn, " turn."
    ]]
    where
        showTurn :: Stage -> Text
        showTurn DevotedServantsTurn    = "Devoted Servant's"
        showTurn FerinasGrunt           = undefined
        showTurn GameOver               = undefined
        showTurn Lynching               = undefined
        showTurn ProtectorsTurn         = "Protector's"
        showTurn ScapegoatsTurn         = "Scapegoat's"
        showTurn SeersTurn              = "Seer's"
        showTurn Sunrise                = undefined
        showTurn Sunset                 = undefined
        showTurn VillagesTurn           = "village's"
        showTurn WerewolvesTurn         = "Werewolves'"
        showTurn WildChildsTurn         = "Wild-child's"
        showTurn WitchsTurn             = "Witch's"
        showTurn WolfHoundsTurn         = "Wolf-hound's"

rolesInGameMessage :: Maybe Text -> [Role] -> Message
rolesInGameMessage mTo roles = Message mTo $ T.concat
    [ "The roles in play are "
    , T.intercalate ", " $ map (\(role, count) ->
        T.concat [role ^. Role.name, " (", T.pack $ show count, ")"])
        roleCounts
    , " for a total balance of ", T.pack $ show totalBalance, "."
    ]
    where
        roleCounts      = map (head &&& length) (groupSortOn (view Role.name) roles)
        totalBalance    = sumOf (traverse . balance) roles

playersInGameMessage :: Text -> [Player] -> Message
playersInGameMessage to players = privateMessage to . T.intercalate "\n" $
    alivePlayersText : [deadPlayersText | any (is dead) players]
    where
        alivePlayersText = T.concat
            [ "The following players are still alive: "
            , T.intercalate ", " (players ^.. traverse . alive . name), "."
            ]
        deadPlayersText = T.concat
            [ "The following players are dead: "
            , T.intercalate ", " (map playerNameWithRole (players ^.. traverse . dead)), "."
            ]
        playerNameWithRole player = T.concat [player ^. name, " (", player ^. role . Role.name, ")"]

waitingOnMessage :: Maybe Text -> [Text] -> Message
waitingOnMessage mTo playerNames = Message mTo $ T.concat
    [ "Waiting on ", T.intercalate ", " playerNames, "..."
    ]

angelJoinedVillagersMessage :: Message
angelJoinedVillagersMessage = publicMessage $ T.unwords
    [ "You hear the Angel wrought with anger off in the distance."
    , "He failed to attract the discriminatory vote of the village"
    , "or the devouring vindictiveness of the lycanthropes."
    , "Now he is stuck here, doomed forever to live out a mortal life as a Villager."
    ]

devotedServantRevealedMessage :: Text -> Message
devotedServantRevealedMessage devotedServantsName = publicMessage $ T.unwords
    [ devotedServantsName, "stands up in horror."
    , "Determined to not let their master's abilities be lost forever,"
    , "she selflessly takes on their role."
    ]

devotedServantJoinedPackMessages :: Text -> [Text] -> [Message]
devotedServantJoinedPackMessages devotedServantsName werewolfNames =
    privateMessage devotedServantsName (T.unwords $ masterWasWerewolfMessage:packMessages)
    : groupMessages werewolfNames (T.unwords
        [ devotedServantsName, "heads towards the woods in search of his master's home and family."
        ])
    where
        masterWasWerewolfMessage = T.unwords
            [ "Upon learning your master was a Werewolf,"
            , "you head towards the woods to learn more about his home and family."
            ]
        packMessages
            | null werewolfNames    = []
            | otherwise             = [T.unwords
                [ "As you enter you see his pack", T.intercalate ", " werewolfNames
                , "waiting for you."
                ]]

ferinaGruntsMessage :: Message
ferinaGruntsMessage = publicMessage $ T.unwords
    [ "Ferina wakes from her slumber, disturbed and on edge."
    , "She loudly grunts as she smells danger."
    ]

playerCannotProtectSamePlayerTwiceInARowMessage :: Text -> Message
playerCannotProtectSamePlayerTwiceInARowMessage to =
    privateMessage to "You cannot protect the same player twice in a row!"

scapegoatChoseAllowedVotersMessage :: [Text] -> Message
scapegoatChoseAllowedVotersMessage allowedVoters = publicMessage $ T.unwords
    [ "On the next day only", T.intercalate ", " allowedVoters, "shall be allowed to vote."
    , "The town crier, realising how foolish it was to kill him, grants him this wish."
    ]

playerMustChooseAtLeastOneTargetMessage :: Text -> Message
playerMustChooseAtLeastOneTargetMessage to =
    privateMessage to "You must choose at least 1 target!"

playerCannotChooseJesterMessage :: Text -> Message
playerCannotChooseJesterMessage to =
    privateMessage to "You cannot choose the Jester!"

playerSeenMessage :: Text -> Player -> Message
playerSeenMessage to target = privateMessage to $ T.concat
    [ targetName, " is aligned with the ", T.pack $ show allegiance', "."
    ]
    where
        targetName  = target ^. name
        allegiance' = target ^. role . allegiance

playerMadeLynchVoteMessage :: Text -> Text -> Message
playerMadeLynchVoteMessage voterName targetName = publicMessage $ T.concat
    [ voterName, " voted to lynch ", targetName, "."
    ]

playerLynchedMessage :: Player -> Message
playerLynchedMessage player
    | is simpleWerewolf player  = publicMessage $ T.concat
        [ playerName, " is tied up to a pyre and set alight."
        , " As they scream their body starts to contort and writhe, transforming into "
        , article playerRole, " ", playerRole ^. Role.name, "."
        , " Thankfully they go limp before breaking free of their restraints."
        ]
    | otherwise                 = publicMessage $ T.concat
        [ playerName, " is tied up to a pyre and set alight."
        , " Eventually the screams start to die and with their last breath,"
        , " they reveal themselves as "
        , article playerRole, " ", playerRole ^. Role.name, "."
        ]
    where
        playerName = player ^. name
        playerRole = player ^. role

noPlayerLynchedMessage :: Message
noPlayerLynchedMessage = publicMessage $ T.unwords
    [ "Daylight is wasted as the townsfolk squabble over whom to tie up."
    , "Looks like no-one is being burned this day."
    ]

jesterLynchedMessage :: Text -> Message
jesterLynchedMessage name = publicMessage $ T.concat
    [ "Just as the townsfolk tie ", name, " up to the pyre, a voice in the crowd yells out."
    , " \"We can't burn ", name, "! He's the joke of the town!\" "
    , name, " the Jester is quickly untied and apologised to."
    ]

scapegoatLynchedMessage :: Text -> Message
scapegoatLynchedMessage name = publicMessage $ T.unwords
    [ "The townsfolk squabble over whom to tie up. Just as they are about to call it a day"
    , "they notice that", name, "has been acting awfully suspicious."
    , "Not wanting to take any chances,", name, "is promptly tied to a pyre and burned alive."
    ]

playerHasAlreadyVotedMessage :: Text -> Message
playerHasAlreadyVotedMessage to = privateMessage to "You've already voted!"

playerMadeDevourVoteMessage :: Text -> Text -> Text -> Message
playerMadeDevourVoteMessage to voterName targetName = privateMessage to $ T.concat
    [ voterName, " voted to devour ", targetName, "."
    ]

playerDevouredMessage :: Player -> Message
playerDevouredMessage player = publicMessage $ T.concat
    [ "As you open them you notice a door broken down and "
    , playerName, "'s guts half devoured and spilling out over the cobblestones."
    , " From the look of their personal effects, you deduce they were "
    , article playerRole, " ", playerRole ^. Role.name, "."
    ]
    where
        playerName = player ^. name
        playerRole = player ^. role

noPlayerDevouredMessage :: Message
noPlayerDevouredMessage = publicMessage $ T.unwords
    [ "Surprisingly you see everyone present at the town square."
    , "Perhaps the Werewolves have left Fougères?"
    ]

playerCannotDevourAnotherWerewolfMessage :: Text -> Message
playerCannotDevourAnotherWerewolfMessage to = privateMessage to "You cannot devour another Werewolf!"

wildChildJoinedPackMessages :: Text -> [Text] -> [Message]
wildChildJoinedPackMessages wildChildsName werewolfNames =
    privateMessage wildChildsName (T.unwords
        [ "The death of your role model is distressing."
        , "Without second thought you abandon the Villagers and run off into the woods,"
        , "towards your old home."
        , "As you arrive you see the familiar faces of", T.intercalate ", " werewolfNames
        , "waiting and happy to have you back."
        ])
    : groupMessages werewolfNames (T.unwords
        [ wildChildsName, "the Wild-child scampers off into the woods."
        , "Without his role model nothing is holding back his true, wolfish, nature."
        ])

playerCannotChooseSelfMessage :: Text -> Message
playerCannotChooseSelfMessage to = privateMessage to "You cannot choose yourself!"

playerPoisonedMessage :: Player -> Message
playerPoisonedMessage player = publicMessage $ T.unwords
    [ "Upon further discovery, it looks like the Witch struck in the night."
    , playerName, "the", playerRole, "is hanging over the side of their bed, poisoned."
    ]
    where
        playerName = player ^. name
        playerRole = player ^. role . Role.name

playerHasAlreadyHealedMessage :: Text -> Message
playerHasAlreadyHealedMessage to = privateMessage to "You've already healed someone!"

playerHasAlreadyPoisonedMessage :: Text -> Message
playerHasAlreadyPoisonedMessage to = privateMessage to "You've already poisoned someone!"

allegianceDoesNotExistMessage :: Text -> Text -> Message
allegianceDoesNotExistMessage to name = privateMessage to $ T.unwords
    [ "Allegiance", name, "does not exist."
    ]

article :: Role -> Text
article role
    | role `elem` restrictedRoles   = "the"
    | otherwise                     = "a"
