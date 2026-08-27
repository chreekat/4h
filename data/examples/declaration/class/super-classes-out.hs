class Foo a

class (Foo a) => Bar a

class
    (Bar a, Foo a) =>
    Baz a

class
    ( Bar a -- Bar?
    , Baz a -- Baz
    , Foo a -- Foo?
    ) =>
    BarBar a
