# Glossary

Shared vocabulary for the recipe finder. Code, tests and docs use these terms with exactly these meanings.

| Term | Meaning | Example |
|---|---|---|
| **Recipe** | A dish from the dataset, with title, times, rating, category, image and its ingredient lines. | *Golden Sweet Cornbread* |
| **Ingredient line** | One raw line of a recipe's ingredient list, as it comes in the dataset. Kept unchanged to display it. | `1 (14 ounce) can chicken broth` |
| **User ingredient** | Something the user says they have at home, as typed in the search. | `chicken` |
| **Match** | A user ingredient *matches* an ingredient line when the line uses that ingredient itself, not a different product made from it. See [ADR 0001](adr/0001-ingredient-matching.md). | `chicken` matches `2 skinless chicken breasts`, but not `1 can chicken broth` |
| **Derived product** | A different product made from an ingredient, recognised by a word such as `broth`, `soup`, `sauce` or `powder` right after it. It does not match the base ingredient. See [ADR 0002](adr/0002-derived-product-words.md). | `chicken broth`, `garlic powder` |
| **Available ingredient line** | An ingredient line matched by at least one user ingredient, or covered by a pantry staple. | |
| **Missing ingredient** | An ingredient line of a recipe that is not available. Shown to the user. | |
| **Pantry staple** | An item we assume every user has, so it never counts as missing. Only exact names count. See [ADR 0003](adr/0003-pantry-staples.md). | `salt`, `ground black pepper`, `water`, `olive oil` (but not `red bell pepper`) |
| **Ranking** | The order of search results: fewest missing ingredients, then most user ingredients used, then highest rating. Only recipes using at least one user ingredient are shown. See [ADR 0004](adr/0004-ranking.md). | |
| **Normalization** | Lowercasing and singularizing words on both sides before matching. See [ADR 0005](adr/0005-normalize-case-and-plurals.md). | `Tomatoes` → `tomato` |
| **Variety** | A more specific kind of an ingredient, named by a word before it. A generic user ingredient covers its varieties. See [ADR 0006](adr/0006-varieties-known-limitation.md). | `cheese` covers `cheddar cheese` |
