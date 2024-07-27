# Parser Texpr Expirimentation
This is an expirimentation repo for a parsing library, attempting
to optimize "general-purpose" single threaded parsing while making the (abstracted) declarative code
as easy as possible to read.

## Status (Unusable/pre-pre-alpha)
Right now, the project is only a semi-functional tokenizer, not meant to be run on others machines (with no outputs, however, the internals of the library portion does put separated tokens into their own list of strings).

The current implementation (unfinished JSON "tokenizer") works at ~12 seconds per 1.4 Gigabytes of data (embedded into the binary, file not uploaded here). (tested on Intel Core i7)

Example sample data (zig concatination format) : "{" ++ "'hello world'!:9999"**10000


## Questions
If you somehow stumble upon this "library" (personal project), and have any questions (such as testing or trying it out yourself), shoot me an email.
```wesley.schell.sh@proton.me```
(hint: comptime linked tries, at an expense of binary file size)
