# AutoHotkey Scripts

A collection of personal AutoHotkey v2 scripts for automating everyday Windows tasks.

## Table of Contents
- [Overview](#overview)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

## Overview

These scripts live in the [scripts](scripts) directory and can be run individually with [AutoHotkey](https://www.autohotkey.com/) version 2. They are small utilities that streamline my workflow on Windows.

## Requirements

- Windows
- [AutoHotkey v2](https://www.autohotkey.com/)
- (Optional for development) [Python 3](https://www.python.org/) to run the linter

## Installation

1. Clone the repository or download the source.
2. Ensure AutoHotkey v2 is installed on your system.

```sh
git clone https://github.com/your-username/autohotkey-scripts.git
cd autohotkey-scripts
```

## Usage

Double-click any `.ahk` file in the `scripts` directory or run it with `AutoHotkey.exe`. Feel free to modify the scripts to match your preferences.

## Development

Run the linter before committing changes:

```sh
python ahk_lint.py --rule-file lint/default_rules.txt
```

By default this applies a set of rules that ensure each script starts with
`#Requires AutoHotkey v2`, declares `#SingleInstance Force`, enables `#Warn`,
ends with a newline, and contains no trailing whitespace. It also warns about
functions that are defined but never used. Additional rules can be enabled with
`--rules` or by providing another rule file. GitHub Actions runs the same linter
on pushes and pull requests.

## Contributing

Pull requests and issue reports are welcome. Please run the linter and ensure
scripts follow existing style conventions before submitting changes.

## License

This project is licensed under the [MIT License](LICENSE).
