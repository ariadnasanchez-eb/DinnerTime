# 2. Tell an ingredient apart from a product made from it with a list of "derived product" words

- **Status:** Accepted
- **Date:** 2026-10-14

## Context

[ADR 0001](0001-ingredient-matching.md) says `chicken` must match `chicken breasts` but not `chicken broth`. We considered three ways to do it:

1. **A list of derived-product words**: if the user ingredient is followed by a word such as `broth`, `stock`, `soup`, `sauce`, `powder` or `bouillon`, the line is a different product.
2. **A closed ingredient catalog**: an `Ingredient` table with canonical names and an autocomplete. It is the most precise option, but building it from the ~9,500 distinct cleaned names in the dataset is too much work for a prototype.
3. **PostgreSQL full-text search on its own**: the fastest option, but it would match `chicken` with `chicken broth`, which breaks ADR 0001.

## Decision

Option 1. A short, explicit list of derived-product words (around 20) lives in the code and decides when an ingredient line is a different product. Examples:

| User types | Line | Match? |
|---|---|---|
| `garlic` | `2 cloves garlic, minced` | Yes |
| `garlic` | `1 teaspoon garlic powder` | No |
| `tomato` | `1 (15 ounce) can tomato sauce` | No |
| `chicken` | `1 can chicken broth` | No |

## Consequences

- The matching logic is ours, simple to explain, and covered by unit tests with real lines from the dataset.
- PostgreSQL stores and filters the data, but the "fuzzy" matching is no longer delegated to its full-text search.
- The list will miss some cases. When it does, the fix is to add a word and a test.
- If precision ever needs to go further, the next step is the closed catalog (option 2).
