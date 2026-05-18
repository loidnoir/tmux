# tmux

My standalone tmux config (no framework), TPM-managed plugins, prefix `C-a`,
vi copy mode, a centralized colour palette, and a minimal status bar.

## Templates

`prefix + t` opens a fuzzy-search popup of project shortcuts; type to filter
and pick one to open (or focus) it as a named window.

Shortcuts are defined in `config.json` (gitignored — paths are
machine-specific). Create your own from this shape:

```json
[
  { "label": "tmux", "path": "~/.config/tmux" },
  { "label": "nvim", "path": "~/.config/nvim" }
]
```

Logic lives in `scripts/projects.sh`.
