{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE CPP #-}
#if defined(__GLASGOW_HASKELL__) && __GLASGOW_HASKELL__ >= 702
{-# LANGUAGE Trustworthy #-}
#endif
-----------------------------------------------------------------------------
-- |
-- Module      :  Data.Profunctor.Rep
-- Copyright   :  (C) 2011-2012 Edward Kmett,
-- License     :  BSD-style (see the file LICENSE)
--
-- Maintainer  :  Edward Kmett <ekmett@gmail.com>
-- Stability   :  provisional
-- Portability :  Type-Families
--
----------------------------------------------------------------------------
module Data.Profunctor.Rep
  (
  -- * Representable Profunctors
    Representable(..), tabulated
  -- * Corepresentable Profunctors
  , Corepresentable(..), cotabulated
  ) where

import Control.Applicative
import Control.Arrow
import Control.Comonad
import Data.Functor.Identity
import Data.Profunctor
import Data.Proxy
import Data.Tagged

-- * Representable Profunctors

-- | A 'Profunctor' @p@ is 'Representable' if there exists a 'Functor' @f@ such that
-- @p d c@ is isomorphic to @d -> f c@.
class (Functor (Rep p), Profunctor p) => Representable p where
  type Rep p :: * -> *
  tabulate :: (d -> Rep p c) -> p d c
  rep :: p d c -> d -> Rep p c

instance Representable (->) where
  type Rep (->) = Identity
  tabulate f = runIdentity . f
  {-# INLINE tabulate #-}
  rep f = Identity . f
  {-# INLINE rep #-}

instance (Monad m, Functor m) => Representable (Kleisli m) where
  type Rep (Kleisli m) = m
  tabulate = Kleisli
  {-# INLINE tabulate #-}
  rep = runKleisli
  {-# INLINE rep #-}

instance Functor f => Representable (UpStar f) where
  type Rep (UpStar f) = f
  tabulate = UpStar
  {-# INLINE tabulate #-}
  rep = runUpStar
  {-# INLINE rep #-}
  
instance Representable (Forget r) where
  type Rep (Forget r) = Const r
  tabulate = Forget . (getConst .)
  {-# INLINE tabulate #-}
  rep = (Const .) . runForget
  {-# INLINE rep #-}

type Iso s t a b = forall p f. (Profunctor p, Functor f) => p a (f b) -> p s (f t)

-- | 'tabulate' and 'rep' form two halves of an isomorphism.
--
-- This can be used with the combinators from the @lens@ package.
--
-- @'tabulated' :: 'Representable' p => 'Iso'' (d -> 'Rep' p c) (p d c)@
tabulated :: (Representable p, Representable q) => Iso (d -> Rep p c) (d' -> Rep q c') (p d c) (q d' c')
tabulated = dimap tabulate (fmap rep)
{-# INLINE tabulated #-}

-- * Corepresentable Profunctors

-- | A 'Profunctor' @p@ is 'Corepresentable' if there exists a 'Functor' @f@ such that
-- @p d c@ is isomorphic to @f d -> c@.
class (Functor (Corep p), Profunctor p) => Corepresentable p where
  type Corep p :: * -> *
  cotabulate :: (Corep p d -> c) -> p d c
  corep :: p d c -> Corep p d -> c

instance Corepresentable (->) where
  type Corep (->) = Identity
  cotabulate f = f . Identity
  {-# INLINE cotabulate #-}
  corep f (Identity d) = f d
  {-# INLINE corep #-}

instance Functor w => Corepresentable (Cokleisli w) where
  type Corep (Cokleisli w) = w
  cotabulate = Cokleisli
  {-# INLINE cotabulate #-}
  corep = runCokleisli
  {-# INLINE corep #-}

instance Corepresentable Tagged where
  type Corep Tagged = Proxy
  cotabulate f = Tagged (f Proxy)
  {-# INLINE cotabulate #-}
  corep (Tagged a) _ = a
  {-# INLINE corep #-}

instance Functor f => Corepresentable (DownStar f) where
  type Corep (DownStar f) = f
  cotabulate = DownStar
  {-# INLINE cotabulate #-}
  corep = runDownStar
  {-# INLINE corep #-}

-- | 'cotabulate' and 'corep' form two halves of an isomorphism.
--
-- This can be used with the combinators from the @lens@ package.
--
-- @'cotabulated' :: 'Corep' f p => 'Iso'' (f d -> c) (p d c)@
cotabulated :: (Corepresentable p, Corepresentable q) => Iso (Corep p d -> c) (Corep q d' -> c') (p d c) (q d' c')
cotabulated = dimap cotabulate (fmap corep)
{-# INLINE cotabulated #-}
