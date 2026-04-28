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

= Prosjekt description

== What was the initial idea / background of the project?

The reason I wanted to make this project is that I really like CLI tools. I use them a lot every day. But I think some of them have unnecessary, bad, and unintuitive syntax. That's why I wanted to make my own tool where I had complete control over the syntax. I also wanted to build a TUI around it, mostly because brick sounded like a fun library to try out. So the idea was to use FFI, MegaParsec, and brick to make a CLI tool for searching for files on my PC. I Also wanted to try to use STM an concurrency to search through the files faster.

== Project goals
  - Make the searching program fast, efficient and safe.
  - Call C functions to retrieve file metadata, with a little as possible overhead.
  - Use the Either monad for error handling. 
  - Use the STM monad for concurrency. 
  - Parse CLI input with MegaParsec.
  - Parse a configuration file. 
  - Write good readable code

== Result
  - I managed to make the CLI with the syntax that I wanted. But I did not implement concurrency, because it was already faster than the built-in find command and I wanted to prioritise testing and the TUI.

  === Implemented
    - Core directory traversal (filter by regex, extension, hidden, ignored).
    - Command execution (`-x` flag substituting `{}`).
    - TUI with `brick` (live search, vim-bindings, open in `$EDITOR`).
    - C FFI bindings (`readdir`, etc.) for fast metadata retrieval.
    - CLI parsing using `megaparsec`.
    - Error handling with `Either`/`ExceptT` for permission issues. 
    - test suite (Tasty, QuickCheck, HUnit).

  === Not Implemented
    - Concurrency (STM / parallel traversal).
    - Configuration file parsing.

== Future extensions
    - Implement concurrent searching

#pagebreak()

= Description of the functional programming techniques



#pagebreak()
= Instructions 
Check the README on gitlab for more info
```bash
cabal build

# eks.
cabal run lambdaSearch -- . -e hs
cabal run lambdaSearch -- -e hs

# For å kjøre testene
cabal test 
```
= Repo URL

#link("https://git.app.uib.no/martin.e.knutsen/inf221-Semesteroppgave")



