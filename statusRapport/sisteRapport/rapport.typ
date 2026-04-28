#set document(title: "Prosjektrapport: lambdaSearch", author: "Martin Elde Knutse")
#set page(paper: "a4", margin: 3cm, numbering: "1")
#set text(font: "New Computer Modern", size: 11pt, lang: "no")
#set par(justify: true, leading: 0.75em)

#set heading(numbering: "1.1")

#show raw.where(block: false): it => text(font: "New Computer Modern Mono", size: 10.5pt, it)

// Kodeblokker

// --- FORSIDE ---
#align(center)[
  #v(5em)
  #text(size: 2.5em, weight: "bold")[lambdaSearch] \
  #v(1em)
  #text(size: 1.5em)[Prosjektrapport] \
  #v(3em)
  #text(size: 1.2em)[INF221 Avansert funksjonell programmering] \
  #v(4em)
  #text(size: 1.2em)[*Martin Elde Knutsen*] \
  #v(1em)
  #datetime.today().display("[day]. [month] [year]")
  #v(5em)
]


#pagebreak()


// --- START PÅ RAPPORTEN ---

= Prosjektbeskrivelse

== Bakgrunn for prosjektet
// What was the initial idea / background of the project?

== Prosjektets mål
// What were the goals of the project?

== Resultat
// How did the project turn out?

== Fremtidig arbeid
// What future extensions can you imagine for the project?


= Brukerveiledning
// Instructions for how to use your project.

```bash
# Bygging av prosjektet
cabal build

# Kjøring av søk
cabal run lambdaSearch -- "søketerm"
```
l
