# 6. Generic ingredients cover their varieties, with no extra rule in v1

- **Status:** Accepted
- **Date:** 2026-10-14

## Context

Words *before* an ingredient name a variety: `cheddar cheese`, `brown sugar`. Some of them are really different products: `peanut butter`, `cream cheese`, `coconut milk`. Handling those exceptions would need another list and more rules.

## Decision

Keep the first version simple. A generic user ingredient matches its varieties (`cheese` matches `shredded cheddar cheese`, `sugar` matches `brown sugar`). No extra rule is added for words placed before the ingredient.

## Consequences

- **Known limitation:** `butter` will also match `peanut butter`, and `milk` will match `coconut milk`.
- The limitation is documented and covered by a test that describes the current behaviour, so it is a conscious choice and not a bug.
- If it matters in practice, the fix is to extend the [derived product words](0002-derived-product-words.md) list with words placed before the ingredient (`peanut`, `cream`, `coconut`…).
