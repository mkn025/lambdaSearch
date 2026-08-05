



# LambdaSearch
- Program som lar deg søke igjennom datamskinen din etter filer
- `lambdaSearch  [input-file]... [options]`

# Flag dokumentasjon
| Flag | Long Form | Purpose |
|------|-----------|---------|
| `-p` | `--pattern` | **SearchPatternFlag** - Defines a search pattern to filter files |
| `-a` | `--show--dots` | **HiddenFilesFlag** - Shows hidden files (those starting with a dot) |
| `-e` | `--extention` | **ExtentionFlag** - Filters or processes files by extension |
| `-i` | `--ignore` | **IgnoreFlag** - Specifies files or paths to exclude from processing |
| `-x` | `--execute` | **ExecuteFlag** - Executes a command on processed files |
| `-c` | `--color` | **Color the output** - Supported colors are red/green/blue (must be lowercase/ green if it fails) | 
| `-f` | `--full-path  ` | **Absoulte/Full- filepath** -  If you want absoulte path|



### Skal implementere
- Skal lage en 

### Kjente feil.
- Excute flagget er litt buggy noen ganger
- Når den parser punktum så kan du ikke ha flere stier

### Clone and install
```bash
git clone https://git.app.uib.no/martin.e.knutsen/inf221-Semesteroppgave.git && cd inf221-Semesteroppgave && cabal install

```
### Om du allerde har innstallert, men vil ha nye edringer
```bash
cabal install --overwrite-policy=always
```

### Eksempelbruk
```bash
lambdaSearch . -e hs
lambdaSearch  -e hs
lambdaSearch  -e hs md txt
lambdaSearch  -e hs -e md

# Bruker POSIX Extended Regular Expressions (ERE)
lambdaSearch -p ^test[0-9]+

# Fungerer med vilkårlig rekkefølge på argumentet. Og med både long og short sammen
lambdaSearch  -p foo -e hs
lambdaSearch --extention hs -p Pars

lambdaSearch /foo/bar -e hs
lambdaSearch "/foo/bar" -e hs
lambdaSearch "/foo/bar" "/bar/foo" -p test -e hs

# Gir jo ut til stdout så du kan bruke med andre cli tools fzf, grep, sk, vim, awk, cut, sed, fmt, tr, cat, ripgrep
lambdaSearch "/foo/bar" "/bar/foo" -p test -e hs
lambdaSearch "/foo/bar" "/bar/foo" -e hs | fzf --tmux 80%  | xargs nvim
lambdaSearch . -e hs | cut -d / -f 10 | sort | uniq -c

# Execute commands on files found substiue {} for filepath, 
# Kanskje litt buggy
lambdaSearch -e hs -x cat {} 


```

![basic demo](./pictures/lambdaSearchDemo.gif)
![fzf](./pictures/fzfLambdaSearch.gif)
