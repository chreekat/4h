module Main where

-- | Something.
newtype Foo = Foo Int
    deriving stock (Eq, Generic, Show)
    deriving newtype (Num)
    deriving anyclass
        ( FromJSON
        , ToJSON
        )
    deriving (Monoid) via (Sum Int)
    deriving
        (Semigroup)
        via (Sum Int)
