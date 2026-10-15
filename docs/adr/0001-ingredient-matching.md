# 1. What counts as a match between a user ingredient and an ingredient line

- **Status:** Accepted
- **Date:** 2026-10-14

## Context

Ingredient lines are free text (`1 (14 ounce) can chicken broth`). When a user types `chicken`, a plain "contains the word" search would also match chicken broth, chicken soup or chicken bouillon, which are different products the user may not have.

## Decision

A user ingredient matches an ingredient line only when the line uses **the ingredient itself** (any cut, form or preparation of it), **not a different product made from it**.

| User types `chicken` | Match? |
|---|---|
| `2 skinless chicken breasts` | Yes: a cut of chicken |
| `1 cup cooked shredded chicken` | Yes: chicken, prepared |
| `1 (14 ounce) can chicken broth` | No: a different product |
| `1 can condensed cream of chicken soup` | No: a different product |

## Consequences

- When in doubt, the app prefers to report an ingredient as **missing** rather than available. Telling users they can cook something they can't is a worse experience than the opposite.
- Matching cannot be a simple substring or full-text search. It needs a rule that tells "the ingredient" apart from "a product made from it", and that rule must be covered by tests.
