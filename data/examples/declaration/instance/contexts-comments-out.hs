instance
    ( -- Foo

      Read
        ( c -- Bar
        , d
        )
    , Read a
    , Read b
    )
    => Read
        ( a -- Baz
        , b
        , ( c -- Quux
          , d
          )
        )
    where
    readsPrec = undefined
