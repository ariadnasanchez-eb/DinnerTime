# 5. Normalize case and plurals on both sides before matching

- **Status:** Accepted
- **Date:** 2026-10-14

## Context

Users and recipes write the same ingredient differently: `eggs` vs `1 egg`, `Tomato` vs `3 tomatoes, diced`. Without normalization these would not match, and users would not understand why.

We considered:

1. **Normalize both sides in our code**: lowercase and singularize with Rails' built-in `singularize`.
2. **PostgreSQL stemming**: more powerful, but it moves matching logic back into the database, against [ADR 0002](0002-derived-product-words.md).
3. **No normalization.**

## Decision

Option 1. Both the user ingredients and the cleaned ingredient names are lowercased and singularized word by word before matching (`tomatoes` → `tomato`, `Eggs` → `egg`).

## Consequences

- All matching logic stays in one place in our code and is tested the same way.
- Typos (`tomatoe`) are out of scope and listed as a future improvement.
- Irregular plurals depend on Rails' inflection rules; any wrong case is fixed with a custom inflection and a test.
