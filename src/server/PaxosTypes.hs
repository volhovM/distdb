{-# LANGUAGE DeriveGeneric   #-}
{-# LANGUAGE TemplateHaskell #-}
-- | Types used in multipaxos consensus algo
module PaxosTypes
       ( Slot
       , CommandId
       , Command
       , ClientRequest
       , ReplicaState (..)
       , slotIn, slotOut, requests, proposals, decisions
       , emptyReplicaState
       , Decision (..)
       , Ballot
       , PValue
       , AcceptorState (..)
       , aBallotNum, accepted
       , emptyAcceptorState
       , PhaseCommitA (..)
       , PhaseCommitB (..)
       , LeaderNotification (..)
       , LeaderState (..)
       , lBallotNum, lActive, lProposals, lScouts, lCommanders, lUniqueId
       , emptyLeaderState
       ) where

import           Control.Distributed.Process (ProcessId)
import           Control.Lens                (makeLenses)
import           Data.Binary                 (Binary (..))
import qualified Data.Map                    as M
import qualified Data.Set                    as S
import           Data.Typeable               (Typeable)
import           GHC.Generics                (Generic)

import           Communication               (Message, SendableLike)
import           Types                       (Command, CommandId)

type Slot = Int
type Ballot = Int
type SubLeaderId = Int
type PValue = (Ballot, Slot, ClientRequest)
type ClientRequest = Message Command

data ReplicaState = ReplicaState
    { _slotIn    :: Slot
    , _slotOut   :: Slot
    , _requests  :: S.Set ClientRequest
    , _proposals :: S.Set (Slot, ClientRequest)
    , _decisions :: S.Set (Slot, ClientRequest)
    } deriving (Show,Read,Typeable,Generic)
makeLenses ''ReplicaState
instance Binary ReplicaState

emptyReplicaState :: ReplicaState
emptyReplicaState = ReplicaState 1 1 S.empty S.empty S.empty


data Decision = Decision Slot ClientRequest
                deriving (Show,Read,Generic,Typeable)

instance Binary Decision
instance SendableLike Decision


data AcceptorState = AcceptorState
    { _aBallotNum :: Ballot
    , _accepted   :: S.Set PValue
    } deriving (Show,Read,Typeable,Generic)

makeLenses ''AcceptorState
instance Binary AcceptorState

emptyAcceptorState :: AcceptorState
emptyAcceptorState = AcceptorState (-1) S.empty

data PhaseCommitA
    = P1A SubLeaderId Ballot
    | P2A SubLeaderId PValue
    deriving (Show,Read,Generic,Typeable)

data PhaseCommitB
    = P1B SubLeaderId Ballot (S.Set PValue)
    | P2B SubLeaderId Ballot
    deriving (Show,Read,Generic,Typeable)

instance Binary PhaseCommitA
instance Binary PhaseCommitB
instance SendableLike PhaseCommitA
instance SendableLike PhaseCommitB


data LeaderState = LeaderState
    { _lBallotNum  :: Ballot
    , _lActive     :: Bool
    , _lProposals  :: S.Set (Slot, ClientRequest)
    , _lScouts     :: M.Map Ballot (S.Set ProcessId, S.Set PValue, Ballot)
    , _lCommanders :: M.Map Ballot (S.Set ProcessId, PValue)
    , _lUniqueId   :: Int
    } deriving (Show,Read,Typeable,Generic)
makeLenses ''LeaderState
instance Binary LeaderState

emptyLeaderState :: LeaderState
emptyLeaderState = LeaderState 0 False S.empty M.empty M.empty 0

-- What leader gets
data LeaderNotification
    = ProposeRequest Slot ClientRequest
    | Adopted Ballot [PValue]
    | Preempted Ballot
    deriving (Show,Read,Generic,Typeable)

instance Binary LeaderNotification
instance SendableLike LeaderNotification
