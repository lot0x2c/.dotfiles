# Doom configuration

`init.el` selects Doom modules; `packages.el` declares extra packages.
`config.el` loads the personal configuration in dependency order. Run `doom sync`
after changing modules or packages, then restart Emacs.

## Layout

| File | Responsibility |
| --- | --- |
| `lisp/lib.el` | Shared path, buffer, and keybinding helpers |
| `lisp/places.el` | Workspace roots and navigation |
| `lisp/editor.el` | Editing, completion, and diagnostics |
| `lisp/windows.el` | Tabs and workspace initialization |
| `lisp/ui.el` | Fonts, theme, and modeline |
| `lisp/banner/` | Startup buffer and its assets |
| `lisp/minuet.el` | Local ghost-text completion in Org files through Ollama |
| `lisp/copilot.el` | Copilot ghost text outside Org; never sees Org files or `~/org` |
| `lisp/org/files.el` | Org paths, agenda sources, and task states |
| `lisp/org/template.el` | New-file templates |
| `lisp/org/inbox.el` | Weekly inbox and its week template |
| `lisp/org/agenda.el` | Review page and source labels |
| `lisp/org/review.el` | Weekly archive and local Git snapshot |
| `lisp/org/daily.el` | Daily task copies, carry-over, and completion sync |
| `lisp/org/commands.el` | Navigation, sorting, links, and bindings |
| `lisp/org/appearance.el` | Heading and link faces |
| `lisp/org/bullets.el` | Fold-state heading markers |
| `lisp/dired.el` | File manager and workspace drawer |
| `lisp/pdf.el` | PDF column, tabs, and viewer integration |
| `lisp/modes.el` | Small LaTeX, Python, and web settings |
| `lisp/proverif.el`, `lisp/pyret.el` | Specialized language integrations |
| `lisp/vendor/` | Upstream code and its license |

## Conventions

Keep shared helpers small. Load `lib` and `places` before their consumers, and
Org paths before Org automation. These files use Doom's `load!` and `after!`;
they are configuration modules, not standalone packages.

Use `ro15rend/` for personal symbols, named hooks and advice, and buffer-local
state for buffer-specific work. Comments explain constraints; docstrings explain
behavior. Keep small language settings together until they warrant a separate file.
Avoid changing GC or startup thresholds without measurements.

Reloading reuses named hooks and advice. Removing a module requires a restart:
loading a smaller configuration does not undo previously installed hooks,
advice, keybindings, or display rules.

`M-a` opens a seven-day agenda, priority A tasks, and undated tasks; the undated
list shows inbox entries from this week only. `M-A` visits `agenda.org`. Agenda
sources are `~/org` files only (`~/uni` course lists are not read), including
`sys/`, `sys.org` and `uni.org`, this semester's deadlines and rubrics by course;
missing sources are skipped until they return. `M-t`
first commits all changes in `~/org` once per day, then starts a new inbox week
if needed and archives tasks closed more than 14 days ago from `agenda.org`,
`sys.org`, `uni.org`, `projects/`, and `sys/`. Archives mirror the source path
under `archive/`.

The daily log copies due and overdue tasks. Finishing a copy in its `agenda`
section finishes its sole open source task with the same title. If the title
matches zero or multiple sources, the copy stays TODO. A new log carries
unfinished tasks outside `agenda` from the latest earlier log, preserving their
headings and notes. Existing titles anywhere in the log suppress another copy.
Automation saves a buffer only when it was unmodified before insertion. New Org
files use a neighboring `template.org` when present.

A new inbox week (`M-x new-week`, or `M-t` once a week) is a fixed template: an
empty heading to write in, open `[#A]` tasks, standing chores, then the week's
dated tasks from `agenda.org` and `uni.org` by day, overdue ones under `mon`.
Pulled tasks are links, not copies: `inbox.org` is an agenda source, and a copy
would show twice and stop the daily log from finishing its source.
`M-x inbox` and `M-t` pull this week's links again, so
finished tasks drop out and new ones appear; lines typed into the week stay.

## Verification

From the repository root:

```sh
doom/tests/run org org-workflow keys pdf settings ui langs stability
doom/tests/run modular
```

The integration runner uses installed Doom packages, a temporary home with fixture
notes, and a headless Sway display. It needs Emacs, emacsclient, Sway, and the
configured language tools. The modular suite omits each optional configuration
file in turn; shared helpers and places are required foundations. Tests disable
language-server startup, so they do not verify live server connections.
