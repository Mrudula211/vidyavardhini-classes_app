## 2025-02-12 - Empty State Icon Update
**Learning:** Returning just text for empty list states is less engaging. Standard UX pattern is to stack a large, relevant icon (size 64, subdued color) above the descriptive text inside a centered column.
**Action:** Always implement this `Column` + `Icon` + `Text` pattern for empty states instead of a basic `Center(child: Text(...))`.
