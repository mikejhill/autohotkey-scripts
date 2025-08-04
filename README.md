# autohotkey-scripts

My personal set of AutoHotkey scripts.

## Development

Run the linter before committing changes:

```sh
python ahk_lint.py --rule-file lint/default_rules.txt
```

By default this applies a set of rules that ensure each script starts with a
`#Requires AutoHotkey v2` directive, declares `#SingleInstance Force`, enables
`#Warn`, ends with a newline, and contains no trailing whitespace. It also warns
about functions that are defined but never used. Additional rules can be enabled
with `--rules` or by providing another rule file. GitHub Actions runs the same
linter on pushes and pull requests.
