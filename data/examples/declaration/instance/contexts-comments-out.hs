instance
    ( Read
        ( c -- Bar
        , d
        )
    , Read a -- Foo
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
