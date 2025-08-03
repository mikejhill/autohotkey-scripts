# autohotkey-scripts

My personal set of AutoHotkey scripts.

## Development

Run the linter before committing changes:

```sh
python lint.py
```

It checks that each script starts with a `#Requires AutoHotkey v2` directive,
has a trailing newline, and contains no trailing whitespace. GitHub Actions
runs the same linter on pushes and pull requests.
