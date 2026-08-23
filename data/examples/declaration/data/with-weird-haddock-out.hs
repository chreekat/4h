data PlusLevel' t
    = -- | @n + ℓ@.
      Plus Integer (LevelAtom' t)
    deriving (Data, Show)
