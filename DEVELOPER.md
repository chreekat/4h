# 4h — Developer notes

## Contributing

Some things to keep in mind when making changes:

* Make the minimal amount of changes
    * Avoid refactoring where possible, don't reformat untouched code
    * 4h tracks Fourmolu, which in turn tracks Ormolu, so reducing the number
      of potential conflicts goes a long way towards maintainability.
* New configuration options are out of scope. 4h has exactly one style; see
  `src/Ormolu/Style.hs`.
* Add a file to `changelog.d/` when applicable (see `changelog.d/README.md`)

### Running tests

The 4h test suite contains the following types of tests:

1. Tests inherited from Ormolu
1. Integration tests

All of these tests can be run with `cabal test` or `stack test`.

To regenerate the printer test outputs (`data/examples/**/*-out.hs`), set
`ORMOLU_REGENERATE_EXAMPLES=1` in the environment before running `test`.

### Running `4h`

After building from source (see `README.md`), you can run 4h with

```bash
scripts/run-4h.sh --mode=inplace ...
```

This script automatically detects whether you built `4h` with Stack or Cabal.
If the auto-detection isn't working out, you can override it by setting
`export BUILD_TYPE={stack,cabal}` in your environment.

This is automatically run on 4h's source code in the pre-commit hooks (see the
"Pre-commit hooks" section) and is checked in CI. If you're not using the
pre-commit hooks, use the above command to manually style the files you changed
(see `.pre-commit-config.yaml` for the files to exclude).

### Pre-commit hooks

We highly recommend turning on pre-commit hooks to run checks every time you
commit. To do so, install [`hooky`](https://github.com/brandonchinn178/hooky)
and run `hooky install` in this directory.

This is optional, and is validated in CI regardless.

### Changing the style

`src/Ormolu/Style.hs` holds the one `PrinterOpts` value the printer consults.
Changing a field there changes 4h's output everywhere, so it is a breaking
change for every user; the set of deviations from Ormolu is meant to stay
closed. If you do change it, regenerate the test outputs (see "Running tests")
and reformat this repository with the new build.

## Instant feedback with GHCID

We often want to immediately see how changes to 4h's source code affect
outputs. Try adding something like this to `Ormolu.hs`:

```hs
import qualified Data.Text.IO as T
import System.Directory (getHomeDirectory)
import System.FilePath ((</>))

main :: IO ()
main = do
  dir <- (</> "Desktop") <$> getHomeDirectory
  ormoluFile conf (dir </> "In.hs") >>= T.writeFile (dir </> "Out.hs")
  where
    conf = defaultConfig {cfgUnsafe = True}
```

Put some interesting code in `In.hs`. The contents of `Out.hs` can be kept up
to date to reflect the result of running 4h on it, by running:

```
ghcid -c 'cabal repl' -W -r --reload=$HOME/Desktop/In.hs
```

## Release a new version

To release a new version, do the following workflow:

1. Create a new branch

    1. Bump version in `4h.cabal`
        * All version bumps should follow [PvP](https://pvp.haskell.org/)

    1. Curate `CHANGELOG.md` (see `changelog.d/README.md`)

    1. Check that `--help` looks good

1. Create PR as usual and merge into `main`
    1. In the `check_sdist` CI job, check the output of the `stack sdist` step
       for any warnings.

1. Go to the GitHub Actions page, click on the "Release" workflow, and click
   "Run workflow" on the `main` branch

## Merging upstream

4h aims to continue merging upstream changes from Fourmolu (and through it,
Ormolu). The following steps merge them in.

1. `cd` into your local copy of the 4h repository
1. Add Fourmolu as an upstream remote: `git remote add fourmolu git@github.com:fourmolu/fourmolu`
1. Check out a new branch: `git switch -c merge-fourmolu main`
1. Pull Fourmolu's git history: `git fetch fourmolu --no-tags`
1. Find the commit corresponding to the new Fourmolu version and merge it: `git merge <commit> -m 'Merge fourmolu-X.Y.Z'`
1. (Recommended) Switch to diff3 conflicts: `git checkout --conflict=diff3`. This provides more context that might be helpful for resolving conflicts. See [docs](https://git-scm.com/book/en/v2/Git-Tools-Advanced-Merging#_checking_out_conflicts).
1. Resolve conflicts + finish merge: `git merge --continue`
1. Follow "Update tests" section to update tests
1. Lint files with `hooky fix -a`
1. Make a PR and merge as usual
    1. **MAKE SURE TO CREATE A MERGE COMMIT**. Don't use the "Squash and merge" or "Rebase and merge" options.

### Resolving conflicts

Follow these steps in order to resolve upstream conflicts:

1. Anything marked "deleted by us" should be deleted. Fourmolu's configuration
   machinery is gone from 4h, and anything upstream adds to it goes too:
   `src/Ormolu/Config/`, `config/`, `web/`, the `fourmolu.yaml` handling, and
   the `PrinterOpts` CLI flags.

    ```shell
    git status --porcelain | awk '/^DU/ { print $2 }' | xargs git rm
    ```

2. A new upstream configuration option means a new field on `PrinterOpts` in
   `src/Ormolu/Style.hs`. Pin it to Ormolu's value unless it makes diffs
   smaller, and record the reasoning next to the field.

3. Conflicts at the following paths should be resolved with `git checkout --ours`:
    * `.github/workflows/ci.yml`
    * `README.md`
    * `DEVELOPER.md`

4. Conflicts at the following paths should be resolved with `git checkout --theirs`:
    * `expected-failures/`

5. Any upstream additions to `CHANGELOG.md` should NOT be kept, but instead be
   added to a new file `changelog.d/fourmolu-X.Y.Z.md`.
    * See `changelog.d/README.md` for more details.

6. Any changes to the cabal file should only be kept if it's for shared config
   (e.g. `tested-with`), but not for `name` or `version`.

7. Resolve easy conflicts as normal.

8. (Optional) Commit the merge, leaving merge conflict markers for difficult
   conflicts. Then resolve the conflicts in separate commits.
    * When you resolve a merge conflict, the old state is completely removed
      from the git history, which can make it difficult to search the git
      history. Doing the change in a separate commit explicitly puts
      non-trivial changes to resolving conflicts into the git history.

### Update tests

1. Regenerate test files (see the "Running tests" section above), then read the
   diff: every changed `*-out.hs` file is a change to 4h's output.

## HLint

Ormolu isn't HLint-clean, and making 4h HLint-clean would increase the diff
with upstream and make merge conflicts more likely, so we shouldn't make
unnecessary changes to solve HLint warnings.

If you're using HLS you may wish to disable HLint on this codebase entirely. In
VSCode, for example, add `"haskell.plugin.hlint.diagnosticsOn": false` to
`4h/.vscode/settings.json`.
