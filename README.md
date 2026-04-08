

# Notat
- Program som lar deg søke igjennom  datamskinen din
- lms {sti} -p {regxPattern}  (--hide-dots {False/Ture}  --exclude [],)?

### Eksempel på tenkt bruk
```bash
lms /Users/lorem/testMappe/ -p lorem122 -a -e md -i exclude ["/Users/lorem/ikkeTaMeddette"] -x "pandoc -o {}.pdf {}"
```

### Hvordan man kjører appen
- Har enda ikke implementert parsing så du må inn i `app/Main.hs` å legge inn manuelt in datastukturene
```bash
git clone git@git.app.uib.no:martin.e.knutsen/inf221-Semesteroppgave.git && cd inf221-Semesteroppgave && cabal run
```












  







