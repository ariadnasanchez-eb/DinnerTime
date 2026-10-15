# 4. Filter to recipes that use at least one user ingredient, then rank by missing ingredients

- **Status:** Accepted
- **Date:** 2026-10-14

## Context

Ranking only by "fewest missing ingredients" lets recipes that use none of the user's ingredients win. For example, a user typing `chicken, tomato` would see an "Ice water" recipe (`water`, `ice`) first, because water is a pantry staple and only the ice is missing.

We considered:

1. **Filter, then rank**: only recipes that use at least one user ingredient, ranked by missing ingredients.
2. **Rank by percentage covered**: short recipes almost always win.
3. **Only complete recipes**: very clear, but usually empty with a few ingredients.

## Decision

Option 1.

- **Filter:** a recipe is shown only if at least one user ingredient matches one of its ingredient lines.
- **Ranking**, in this order:
  1. Fewest missing ingredients.
  2. Most user ingredients used.
  3. Highest rating.
- **Limit:** the first 20 results.

## Consequences

- Every result answers "what can I cook with what I have?".
- Each ranking criterion can be explained in one sentence and tested with a handful of fixture recipes.
- Pagination beyond 20 results is left as a future improvement.
