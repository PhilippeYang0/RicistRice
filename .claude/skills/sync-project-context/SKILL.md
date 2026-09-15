---
name: sync-project-context
description: Update CLAUDE.md after a brainstorm, plan, or implementation session in this repo so it stays an accurate, current snapshot of the rice's state - decisions made, items resolved, still-open questions. Use after /superpowers:execute-plan, after making or reversing a stack decision (compositor, bar/shell, wallpaper daemon, color engine, aesthetic direction, which rice to adapt from), or whenever CLAUDE.md's "Open items" or "Stack decisions" sections no longer match reality. Do NOT use for routine code edits that don't change a decision or resolve an open item.
---

# Sync project context into CLAUDE.md

CLAUDE.md is this repo's persistent memory across sessions - the next Claude
Code invocation reads it cold, with none of this conversation's context. If
it drifts from what actually got decided or built, the next session starts
from a wrong premise. This skill closes that loop: after real work happens,
reconcile CLAUDE.md against it.

## When to run this

- After finishing a `/superpowers:execute-plan` run that changed the repo.
- After a `/superpowers:brainstorm` or `/superpowers:write-plan` session
  that settled a previously-open question (aesthetic direction, which
  r/unixporn rice to adapt from, a stack swap like matugen -> pywal).
- Any time you notice a claim in CLAUDE.md ("not yet decided", a stack
  table row, an open item) that the current repo state contradicts.

Skip it for routine edits (fixing a QML typo, tweaking a keybind value)
that don't change a decision or resolve/open an item worth remembering.

## How to update it

1. **Read the live CLAUDE.md first** - never assume its current content
   from memory or from earlier in a long conversation; it may have changed.
2. **Diff reality against the doc.** Walk these sections and check each
   claim against what this session actually did or decided:
   - `Stack decisions` table - only reflects confirmed/implemented choices,
     never a choice merely discussed. If something replaced a prior choice
     (e.g. matugen dropped for pywal), update the row and note why in
     `Notes`, don't just delete history silently.
   - `Aesthetic direction` line - update only once genuinely decided, not
     tentatively leaning.
   - `Open items to resolve before/while building this out` - remove items
     this session resolved; add newly discovered ones (a new Ubuntu/Arch
     package gap, a deferred decision that came up mid-implementation).
   - `Repo structure` - update only if directories were actually added
     (e.g. first real content landed in `dotfiles/` or `refs/`).
3. **Edit narrowly.** Use targeted edits to the specific lines/rows that
   changed - this is not a rewrite pass. Preserve the file's existing
   voice, table format, and section order.
4. **Never invent a decision.** Only record what this session actually
   decided or built. A brainstorm that surfaced options without a pick
   stays an open item, not a stack decision.
5. **Respect the ground rules already in CLAUDE.md** while editing it -
   e.g. don't restructure `hyprland.conf` guidance, don't touch `refs/`
   as a side effect, keep Ubuntu/apt-vs-Arch/pacman framing intact.
6. **Confirm the diff with the user** in your summary (what changed in
   CLAUDE.md and why) rather than silently editing and moving on - it's
   the project's source of truth, so changes to it should be visible.
