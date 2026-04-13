# Notat
- Program som lar deg søke igjennom  datamskinen din
- lambdaSearch {sti}  

### Gjort siden innleveringen 
- Gjort det mulig å søke med `.` eller ingen argumenter. Dette vil da til da bruke working directory

### Mangler.
- Kjøre en kommando på filer den søker etter
- Lage TUI for søkingen
- Treversere paralelt med STM monaden
- Fuzzy search funksjonalitet.

```bash
git clone https://git.app.uib.no/martin.e.knutsen/inf221-Semesteroppgave.git && cd inf221-Semesteroppgave && cabal install
```

##  Eksmepl på noen som kjører

```bash
lambdaSearch . -e java
lambdaSearch  -e java
lambdaSearch "/foo/bar" -e java
lambdaSearch "/foo/bar" "/bar/foo" -p test -e java

# Gir jo ut til stdout så du kan bruke med andre cli tools fzf, grep, sk, tmux, nvim, awk, cut, sed
lambdaSearch "/foo/bar" "/bar/foo" -p test -e java
lambdaSearch "/foo/bar" "/bar/foo" -e hs | fzf --tmux 80%  | xargs nvim
```

![nvim fzf tmux showcase](./pictures/lamdaSearchTmuxNvimshowcase.gif)

# Flag dokumentasjon

| Flag | Long Form | Purpose |
|------|-----------|---------|
| `-p` | `--pattern` | **SearchPatternFlag** - Defines a search pattern to filter files |
| `-a` | `--show--dots` | **HiddenFilesFlag** - Shows hidden files (those starting with a dot) |
| `-e` | `--extention` | **ExtentionFlag** - Filters or processes files by extension |
| `-i` | `--ignore` | **IgnoreFlag** - Specifies files or paths to exclude from processing |
| `-x` | `--execute` | **ExecuteFlag** - Executes a command on processed files |








