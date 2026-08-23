{-# LANGUAGE ExistentialQuantification #-}

data Foo = forall a b. (Eq b, Show a) => Bar
    { foo :: a
    , bars :: b
    }
