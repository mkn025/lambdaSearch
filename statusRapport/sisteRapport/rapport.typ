#set document(title: "Prosjektrapport: lambdaSearch", author: "Martin Elde Knutse")
#set page(paper: "a4", margin: 2cm, numbering: "1")
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

== Monadic Parsing Combinators 
- When parsing the for the cli i use of lot these Combinators.  Making it very readable and elagant. 
- Eksample:

```hs
pFlags :: Parser DataFlags
pFlags = choice
    [ SearchPatternFlag <$> ((string' "-p" <|> string  "--pattern"   ) *> sc *> parseWord)
     , HiddenFilesFlag  <$  ( string' "-a" <|> string  "--show--dots")
       ...
```
- Here, I first use the `fmap` infix operator (`<$>`). Using `fmap` allows me to lift the parsed result into the `DataFlags` context effortlessly. 

- Next is the acctual parser. Three things to notice here:
- first is the use of `string'`, which parses case-insensitively, meaning both `-p` and `-P` will work. 

- Second, I use the `<|>` operator, which here sort of acts like a or. It tries to parse `-p`, and if that fails, it tries to parse `--pattern`. Because the type signature of this operator is `f a -> f a -> f a`, you can treat the combined expression as a single parser. This means anywhere you parse one thing, you can easily try to parse alternatives without any hassle. Of course, the inner type `a` must be the same for both parsers.

- Third, after parsing the flag, I treat that portion of the string as having been "consumed." Since the next goal is to parse the actual argument and disregard the prefix, I use the `*>` operator, which sequences two actions and discards the result of the first. I sequence this with `sc` to handle whitespace, and finally, the parsed word is lifted into the `DataFlags` constructor using `fmap`.

- And it just using this paring combinators that makes everything so effortlessly when i parsing the cli.

- On line under we do the same. But we use `<$` because HiddenFilesFlag does not take any argument. When we parse parse we Just want it do be Parser HiddenFilesFlag. 


== Monad Transformers and Monadic Error Handling

== Higher-Order Functions and Folds 


== In the parser
- To keep track of which flags the user passed in the CLI, I used a functional fold. This is a super clean way to build up the configuration state purely.
- Example:

```hs
parseFlags :: Parser Arguments
parseFlags = do
  fs <- parseAllFlags 
  pure $ foldl' applyFlag emptyFilterFlags fs  
```
- Here, `parseAllFlags` returns a list of parsed `DataFlags`. 

- To process them, I use `foldl'` (the strict left fold) to iterate over this list. Why strict fold? Beacuse we avoid space leaks with accumulating expressions on the heap. It is probably not an issue on my program, but it is just good practice.


- The magic happens with the `applyFlag` function, which has the type signature `Arguments -> DataFlags -> Arguments`. It basically acts as a state transition function. It takes the current `Arguments` state, looks at the new `DataFlags` we just parsed, and returns a newly updated `Arguments` record.

- So we start with `emptyFilterFlags` as our base state, fold over the list of parsed flags, and get our fully constructed configuration without a single mutable variable.

== In the travaveselfunction
#lorem(100)



== View Patterns
I made  use of  `ViewPatterns` language extension to keep my pattern matching concise. It lets me evaluate a function directly inside the pattern match, saving me from writing nested `case` expressions or messy guard clauses.

- Example:

```hs
getExtentionFilter :: FilterFlags -> RawFilePath ->  Bool
getExtentionFilter sf fp = case extention sf of
                        Nothing    ->  True
                        (Just ext) -> case getFileExtention fp of
                                        Nothing     -> False
                                        (Just curr) -> curr == ext
```
- Becomes:

```hs
getExtentionFilter :: Arguments -> RawFilePath -> Bool
getExtentionFilter (extention -> Nothing) _                                = True
getExtentionFilter (extention -> Just _ )  (getFileExtention -> Nothing)   = False
getExtentionFilter (extention -> Just ext) (getFileExtention -> Just curr) = curr == ext
```
- I think this reads a lot better than the case switch statment, because it immediatly tells what output you get on that spesifc imput

== FFI and Monadic Error Handling
 To make the directory traversal as fast as possible, I used the Foreign Function Interface (FFI) to bind directly to C POSIX functions. But to keep the Haskell side safe, I wrapped these impure calls in Monad Transformers to handle error and end of dir exeptions.

- Example:
```hs
type DirContentT = ExceptT DirError IO (Maybe DirContent)

readDirEnt :: DirStream ->  DirContentT
readDirEnt dir = ExceptT readContent
    where
    readContent :: IO (Either DirError (Maybe DirContent))
    readContent = do
      -- ... raw IO and FFI calls to c_readdir ...
```


- First, I define `DirContentT` using `ExceptT`. This layers an exception context (`DirError`) over the `IO` monad. This lets me sequence IO actions but still cleanly short-circuit if a specific directory error happens (like a permission denied error).

- Inside `readContent`, I do the actual raw `IO` calls to the C function `c_readdir`. Depending on the `Errno` returned by C, I can return `pure . Right $ Nothing` (if we hit the end of the folder) or `pure . Left $ ReadDirErr err` if it actually failed.

- By wrapping this `Either` result in the `ExceptT` constructor, the rest of my traversal code can just bind (`>>=`) through the directory reads. It handles the unsafe C errors, in a functional way without crashing the program.


Another thing i want to talk about i the calls done with FFI
```hs
foreign import ccall safe "readdir"
  c_readdir :: Ptr CDir -> IO (Ptr CDirent) 

foreign import ccall unsafe "__hscore_d_name"
  c_name :: Ptr CDirent -> IO CString

foreign import ccall unsafe "__posixdir_d_type"
  c_type :: Ptr CDirent -> IO DirType
```
- As you can see the `c_readdir ` uses a safe call but the other two uses `unsafe` Why is this? Normaly when we make `safe` call with the FFI the runtime releases its lock on the OS thread before doing any C stuff. This allows any other Haskell thread to grab the capebility ("basically the right to run haskell code"). This of course results in a bit of overhead. When we do an unsafe call it skips all of this, witch can block the entire haskell execution until `c` returns







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



