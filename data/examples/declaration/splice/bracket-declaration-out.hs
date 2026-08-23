{-# LANGUAGE TemplateHaskell #-}

[d|data T a where Foo :: T ()|]

foo =
    [d|
        foo :: Int -> Char

        bar = 42
        |]

[d|
    data T = T
        deriving (Bounded, Enum, Eq, Ord, Show)
    |]

$(do [d|baz = baz|])

$(singletons [d|data T = T deriving (Bounded, Enum, Eq, Ord, Show)|])

$( singletons
    [d|
        data T = T
            deriving (Bounded, Enum, Eq, Ord, Show)
        |]
 )

foo = [d| type X = * |]

foo =
    [d|
        type X = *

        data A
        |]
