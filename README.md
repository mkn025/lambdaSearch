# Notat
- Program som lar deg søke igjennom  datamskinen din
- lms {sti} -p {regxPattern}  (--hide-dots {False/Ture}  --exclude [],)?


### Hvordan man kjører appen
- Har enda ikke implementert parsing så du må inn i `app/Main.hs` å legge inn manuelt in datastukturene

```bash
git clone git@git.app.uib.no:martin.e.knutsen/inf221-Semesteroppgave.git && cd inf221-Semesteroppgave && cabal run
```



# Flag dokumentasjon

| Flag | Long Form | Purpose |
|------|-----------|---------|
| `-p` | `--pattern` | **SearchPatternFlag** - Defines a search pattern to filter files |
| `-a` | `--show--dots` | **HiddenFilesFlag** - Shows hidden files (those starting with a dot) |
| `-e` | `--extention` | **ExtentionFlag** - Filters or processes files by extension |
| `-i` | `--ignore` | **IgnoreFlag** - Specifies files or paths to exclude from processing |
| `-x` | `--execute` | **ExecuteFlag** - Executes a command on processed files |

## Eksmepel på hvordan man kjører appen (Fungerer ikke enda)
```bash
lms "/Users/lorem/testMappe/" -p lorem122 -a -e md -i "/foo/bar/foo/bar" "/foo/bar/foo/bar"  -x "pandoc -o {}.pdf {}"
lms /Users/lorem/testMappe/ -p lorem122 -e md -i "/Users/lorem/ikkeTaMeddette" -x "pandoc -o {}.pdf {}"
lms -p cola -e png #søker etter alle filer med cola i seg som er en png. mappen du står i


```

##  Eksmepl på noen som kjører
-  Tar ikke argumnter enda. Du må derfor  kjøre lms... etter at du har kjøre cabal run (bruker bare `getLine` forløpig)
```bash
cabal run 
lms "/Users/martineldeknutsen/Dev/UiB/inf221" -e java  
```

![how it works gif]("inf221-Semesteroppgave/pictures/lamdaSerchVideo.gif") 







