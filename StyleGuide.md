# Style Guide

The following documents the style guide for writing code on the Ether Deck Mk2.

## Principles

**Only Assembly:** All business logic is written in assembly.

**High Function, Higher Form:** Optimize where possible, but prefer
form over optimization where optimization conflicts with the remainder of the
guide.

**Prefer Form On Known Optimizer Rules:** When known Yul Optimizer rules allow
for better form, choose form.

**Single Line Operations:** No operation may contain multiple lines. The 120
character line limit is generous for most operations. Any operation that
requires over 120 characters can be prefaced with a variable cache for form.

**Double Newline Between Operations:** All operations must contain an empty line
before the next.

**Minimal For-Loops:** All for-loops must contain no logic outside of the loop
body.

**Variables, Checks, Memory:** Where possible, prefer stack variable
allocation before check compositions, check compositions before memory writes.
Make exceptions where necessary.

**Compose and Defer Checks:** Compose all checks into a single boolean variable,
use a single branch for validation unless otherwise applicable for ERC
compliance.

**Document All Directives:** Each line of business logic includes an
accompanying directive in the dev tag of the function's natspec.

**Directives Are Indexed:** Directives are numbered, index 1, double digits.
Nested directives are lettered, index a. Double nested directives are double
lettered, index aa, left letter is the parent directive, right letter is index.

**Minimize Imports:** Import only when necessary. Each document should contain
all possible business logic associated with its contract.

**Namespace Storage:** Storage variable slots are computed as a keccak hash
minus one of "EtherDeckMk2" concatenated with the slot name, in pascal case,
delimited by a period character.

**Document Storage Variable Preimages:** Storage variable slots preimages are
documented under a dev tag after the directives tag.

**Use Named Arguments:** Where possible, use the named arguments of calldata
variables, including lengths and offsets, with the exception of product types in
calldata.

**Minimize Memory:** Minimize memory size. Where possible, reuse memory.

**Pad Selectors:** Pad selectors to 32 bytes where the four bytes are
left-aligned.

**Precompute Event Hashes:** Precompute event hashes and use the hashes inline.

**Literals are Hexadecimal:** Offsets center around increments of 32, base 16 is
intuitive for reasoning about offsets.

**Minimize Overflow Checks:** Overflow checks are limited to where overflows
break invariants.

**Brackets Contain Whitespace:** Brackets must contain whitespace.

**Prefer Function Argument Over Modifier Movement:** When a function signature
is greater than 120 characters, move function arguments before moving function
modifiers.
