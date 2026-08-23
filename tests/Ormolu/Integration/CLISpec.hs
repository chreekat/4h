module Ormolu.Integration.CLISpec (spec) where

import Control.Monad (forM_)
import Ormolu.Integration.Utils (ProcessSpec (..), get4hExe, proc, readFrom, readProcess)
import System.Directory (createDirectoryIfMissing)
import System.FilePath (takeDirectory, (</>))
import System.IO.Temp (withSystemTempDirectory)
import Test.Hspec

spec :: Spec
spec =
    describe "4h CLI functionality" . beforeAll get4hExe $ do
        it "formats stdin when no files specified" $ \exe4h -> do
            stdout <- readFrom $ (proc exe4h ["--no-cabal"]) {procStdin = unformattedCode}
            stdout `shouldBe` formattedCode

        it "formats stdin when stdin specified" $ \exe4h -> do
            stdout <- readFrom $ (proc exe4h ["--no-cabal", "-"]) {procStdin = unformattedCode}
            stdout `shouldBe` formattedCode

        it "recursively finds files in directories" $ \exe4h -> do
            withTempDir $ \tmpdir -> do
                let hsFile = tmpdir </> "test.hs"
                writeFile' hsFile unformattedCode

                output <- readProcess exe4h [tmpdir]
                output `shouldBe` formattedCode

        it "ignores files in specific directories" $ \exe4h -> do
            withTempDir $ \tmpdir -> do
                let testFiles =
                        [ tmpdir </> "test1.hs"
                        , tmpdir </> "foo/test2.hs"
                        ]
                let ignoredFiles =
                        [ tmpdir </> ".stack-work/test.hs"
                        , tmpdir </> "dist-newstyle/test.hs"
                        ]
                forM_ (testFiles ++ ignoredFiles) $ \fp -> do
                    writeFile' fp unformattedCode

                _ <- readProcess exe4h ["-i", tmpdir]
                forM_ testFiles $ \fp -> do
                    output <- readFile fp
                    output `shouldBe` formattedCode
                forM_ ignoredFiles $ \fp -> do
                    output <- readFile fp
                    output `shouldBe` unformattedCode
    where
        withTempDir = withSystemTempDirectory "4h-cli-test"
        writeFile' fp s = do
            createDirectoryIfMissing True (takeDirectory fp)
            writeFile fp s
        unformattedCode = "main=print(1+1)\n"
        formattedCode = "main = print (1 + 1)\n"
