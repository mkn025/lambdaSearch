# Notat
- Program som lar deg søke igjennom  datamskinen din
- lambdaSearch {sti}  

### Gjort siden innleveringen 
- Gjort det mulig å søke med `.` eller ingen argumenter. Dette vil da til da bruke working directory

### Mangler.
- Lage TUI for søkingen
- Treversere paralelt med STM monaden
- Fuzzy search funksjonalitet.

```bash
git clone https://git.app.uib.no/martin.e.knutsen/inf221-Semesteroppgave.git && cd inf221-Semesteroppgave && cabal install
```

## Eksempelbruk
```bash
lambdaSearch . -e hs
lambdaSearch  -e hs

# Fungerer med vilkårlig rekkefølge på argumentet. Og med både long og short sammen
lambdaSearch  -p foo -e hs
lambdaSearch --extention hs -p Pars

lambdaSearch /foo/bar -e hs
lambdaSearch "/foo/bar" -e hs
lambdaSearch "/foo/bar" "/bar/foo" -p test -e hs

# Gir jo ut til stdout så du kan bruke med andre cli tools fzf, grep, sk, vim, awk, cut, sed etc...
lambdaSearch "/foo/bar" "/bar/foo" -p test -e hs
lambdaSearch "/foo/bar" "/bar/foo" -e hs | fzf --tmux 80%  | xargs nvim
lambdaSearch . -e hs | cut -d / -f 10 | sort | uniq -c

# Execute commands on files found substiue {} for filepath
# Maybe a little buggy stil
lambdaSearch -e hs -x cat {} 
```

![nvim fzf tmux showcase](./pictures/lamdaSearchTmuxNvimshowcase.gif)
![command execution](./pictures/showCaseProcessExecution.gif)

# Flag dokumentasjon

| Flag | Long Form | Purpose |
|------|-----------|---------|
| `-p` | `--pattern` | **SearchPatternFlag** - Defines a search pattern to filter files |
| `-a` | `--show--dots` | **HiddenFilesFlag** - Shows hidden files (those starting with a dot) |
| `-e` | `--extention` | **ExtentionFlag** - Filters or processes files by extension |
| `-i` | `--ignore` | **IgnoreFlag** - Specifies files or paths to exclude from processing |
| `-x` | `--execute` | **ExecuteFlag** - Executes a command on processed files |








