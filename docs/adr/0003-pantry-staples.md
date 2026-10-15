# 3. Assume a short, exact list of pantry staples

- **Status:** Accepted
- **Date:** 2026-10-14

## Context

Almost every recipe uses salt, pepper, water or oil, but users rarely type them. Without assuming them, very few recipes would ever appear as complete. However, a loose rule such as "anything containing `pepper`" would wrongly cover `1 red bell pepper`, and "anything containing `oil`" would cover less common oils such as sesame or coconut oil.

We considered:

1. **A fixed, exact list** of staples.
2. **Editable checkboxes** in the search form, pre-ticked with the same list.
3. **No staples**: the user types everything.

## Decision

Option 1. A short constant in the code lists the exact staples: `salt`, `black pepper`, `ground black pepper`, `water`, `vegetable oil`, `olive oil` and `cooking spray`. A staple covers an ingredient line only when the cleaned ingredient name is exactly one of them, never by "contains". The search page tells the user: *"We assume you have salt, black pepper, water and cooking oil."*

## Consequences

- `1 red bell pepper` and `2 tablespoons sesame oil` still count as missing.
- The list is visible to the user, so the assumption is never hidden.
- Editable checkboxes (option 2) are the natural next step and are listed as a future improvement.
- A line that lists several staples joined by "and" counts too, as long as **every** part is an exact staple: `salt and ground black pepper` is covered, `salt and red bell pepper` is not.
