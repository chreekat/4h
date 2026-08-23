magnify
    :: forall outertag innertag t outer inner m a
     . ( HasReader outertag outer m
       , forall m'
          . (HasReader outertag outer m')
         => HasReader innertag inner (t m')
       , forall x. Coercible (t m x) (m x)
       )
    => (forall m'. (HasReader innertag inner m') => m' a) -> m a
