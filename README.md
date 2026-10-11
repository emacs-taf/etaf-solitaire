# Verdant Solitaire

A native ETAF card table built as an independent GameKit application. OpenSpiel
owns the K+ Klondike rules, legal moves, chance outcomes and undo/redo history;
this application owns presentation, selection and the launch command.

K+ Klondike folds repeated draws into currently available waste-card choices.
It is not a Windows Klondike rules emulator. Both an ivory/sage light theme and
a graphite dark theme are available; switching themes preserves the deal.

## Install and play

Requires Emacs 29.1+, ETAF, etaf-ui, GameKit with its OpenSpiel backend installed,
and the catalog's `etaf-playing-card` component. Add the provider repository
roots and this repository to `load-path`:

```elisp
(require 'etaf-solitaire)
(etaf-solitaire-open)
```

Click a face-up card, then a highlighted destination. Use `D` to browse available
waste cards, `H` for a legal-move hint, `U` / `Y` for undo/redo and `T` to switch
appearance. The toolbar includes new deal, save, load and help. `Q` closes the
current game without an implicit save.

See the [manual](docs/manual.md) for rule boundaries, configuration and recovery.
The [package entry](etaf-solitaire.el) owns the public API inventory.
Run `make check` for compilation and public behavior scenarios; GUI appearance
and performance are separate acceptance requirements.
