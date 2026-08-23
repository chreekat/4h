{-# LANGUAGE RecordWildCards #-}

module Ormolu.CabalInfoSpec (spec) where

import Data.Set qualified as Set
import Distribution.Types.PackageName (unPackageName)
import Ormolu.Config (DynOption (..))
import Ormolu.Utils.Cabal
import System.Directory
import System.FilePath
import System.IO.Temp (withSystemTempDirectory)
import Test.Hspec

spec :: Spec
spec = do
    describe "findCabalFile" $ do
        let findsOrmoluCabal start expectedCabalFile = do
                Just absolute <- findCabalFile start
                absolute `shouldSatisfy` isAbsolute
                makeRelativeToCurrentDirectory absolute `shouldReturn` expectedCabalFile
        it "returns correct absolute path" $
            findsOrmoluCabal "src/Ormolu/Config.hs" "4h.cabal"
        it "finds correct path even when it starts from nonsense" $
            findsOrmoluCabal "a/b/c/d/e" "4h.cabal"
        it "returns Nothing when it cannot find a cabal file" $
            findCabalFile "/foo.hs" `shouldReturn` Nothing
        it "does not consider directories as .cabal files" $
            withSystemTempDirectory "" $
                \dir -> do
                    createDirectory $ dir </> ".cabal"
                    cabalFile <- findCabalFile (dir </> "foo/bar.hs")
                    cabalFile `shouldBe` Nothing
    describe "parseCabalInfo" $ do
        it "extracts correct cabal info from 4h.cabal for src/Ormolu/Config.hs" $ do
            (mentioned, CabalInfo {..}) <- parseCabalInfo "4h.cabal" "src/Ormolu/Config.hs"
            mentioned `shouldBe` True
            unPackageName ciPackageName `shouldBe` "4h"
            ciDynOpts `shouldBe` [DynOption "-XGHC2021"]
            Set.map unPackageName ciDependencies `shouldBe` Set.fromList ["Cabal-syntax", "Diff", "MemoTrie", "ansi-terminal", "array", "base", "binary", "bytestring", "choice", "containers", "directory", "file-embed", "filepath", "ghc-lib-parser", "megaparsec", "mtl", "syb", "text"]
            ciCabalFilePath `shouldSatisfy` isAbsolute
            makeRelativeToCurrentDirectory ciCabalFilePath `shouldReturn` "4h.cabal"
        it "extracts correct cabal info from 4h.cabal for tests/Ormolu/PrinterSpec.hs" $ do
            (mentioned, CabalInfo {..}) <- parseCabalInfo "4h.cabal" "tests/Ormolu/PrinterSpec.hs"
            mentioned `shouldBe` True
            unPackageName ciPackageName `shouldBe` "4h"
            ciDynOpts `shouldBe` [DynOption "-XGHC2021"]
            Set.map unPackageName ciDependencies `shouldBe` Set.fromList ["Cabal-syntax", "Diff", "QuickCheck", "base", "bytestring", "choice", "containers", "directory", "filepath", "ghc-lib-parser", "hspec", "hspec-megaparsec", "4h", "megaparsec", "path", "path-io", "pretty", "process", "temporary", "text"]
            ciCabalFilePath `shouldSatisfy` isAbsolute
            makeRelativeToCurrentDirectory ciCabalFilePath `shouldReturn` "4h.cabal"
        it "handles correctly files that are not mentioned in 4h.cabal" $ do
            (mentioned, CabalInfo {..}) <- parseCabalInfo "4h.cabal" "src/FooBob.hs"
            mentioned `shouldBe` False
            unPackageName ciPackageName `shouldBe` "4h"
            ciDynOpts `shouldBe` []
            Set.map unPackageName ciDependencies `shouldBe` Set.fromList ["base"]
            ciCabalFilePath `shouldSatisfy` isAbsolute
            makeRelativeToCurrentDirectory ciCabalFilePath `shouldReturn` "4h.cabal"
        it "handles `hs-source-dirs: .`" $ do
            (_, CabalInfo {..}) <- parseTestCabalInfo "Foo.hs"
            ciDynOpts `shouldContain` [DynOption "-XImportQualifiedPost"]
        it "handles empty hs-source-dirs" $ do
            (_, CabalInfo {..}) <- parseTestCabalInfo "Bar.hs"
            ciDynOpts `shouldContain` [DynOption "-XImportQualifiedPost"]
    where
        parseTestCabalInfo f =
            parseCabalInfo "data/cabal-tests/test.cabal" ("data/cabal-tests" </> f)
