{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE TemplateHaskell #-}
module MyGame
  ( initGame2
  , moves
  , decrease_step
  , check_die
  , Game2(..)
  , MyDirection(..)
  , myheight, mywidth
  , player, d, gameOver, stepsRemain
  ) where

import Control.Applicative ((<|>))
import Control.Monad (guard)
import Data.Maybe (fromMaybe)

import Control.Lens hiding ((<|), (|>), (:>), (:<))
import Control.Monad.Trans.Maybe
import Control.Monad.Trans.State
import Control.Monad.Extra (orM)
import Data.Sequence (Seq(..), (<|))
import qualified Data.Sequence as S
import Linear.V2 (V2(..), _x, _y)
import System.Random (Random(..), newStdGen)

-- Types

type Coord = V2 Int

--type Rock = Seq Coord

data Game2 = Game2
  { _d      :: MyDirection       -- ^ direction
  , _player :: Coord             -- ^ the location of the player will be modified via I/O
  , _gameOver :: Bool
  , _stepsRemain :: Int
  } deriving (Show)


data Stream a = a :| Stream a
  deriving (Show)

data MyDirection
  = MyNorth
  | MySouth
  | MyEast
  | MyWest
  deriving (Eq, Show)

makeLenses ''Game2
-- Constants

myheight, mywidth :: Int
myheight = 20
mywidth = 20

-- Functions

-- | Step forward in time

initGame2 :: IO Game2
initGame2 = do
  let x = 0
      y = 0
      g = Game2
        {
          _d = MySouth
        , _player = (V2 x y)
        , _gameOver = False
        , _stepsRemain = 10
        }
  return (execState initState g)

initState :: State Game2 ()
initState = do
  s <- get
  put s

moves :: MyDirection -> Game2 -> Game2
moves MyNorth g = do
  let (V2 x y) = g ^. player
  if y >= myheight - 1 then g
  else if g ^. gameOver == True then g
  else 
    (check_die (decrease_step g)) & player %~ (\(V2 a b) -> (V2 a (b+1)))

moves MyEast g = do
  let (V2 x y) = g ^. player
  if x >= mywidth - 1 then g
  else if g ^. gameOver == True then g
  else 
    (check_die (decrease_step g)) & player %~ (\(V2 a b) -> (V2 (a+1) b))

moves MyWest g = do
  let (V2 x y) = g ^. player
  if x <= 0 then g
  else if g ^. gameOver == True then g
  else 
    (check_die (decrease_step g)) & player %~ (\(V2 a b) -> (V2 (a-1) b))

moves MySouth g = do
  let (V2 x y) = g ^. player
  if y <= 0 then g
  else if g ^. gameOver == True then g
  else 
    (check_die (decrease_step g)) & player %~ (\(V2 a b) -> (V2 a (b-1)))

moves _ g = g

decrease_step :: Game2 -> Game2
decrease_step g =  g & stepsRemain %~ (\n -> (n-1))

check_die :: Game2 -> Game2
check_die g = do
  if g ^. stepsRemain == 0 then g & gameOver %~ (\_ -> True)
  else g

fromList :: [a] -> Stream a
fromList = foldr (:|) (error "Streams must be infinite")
