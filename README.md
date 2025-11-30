# Notevault (`nv`)

---

<a href="https://github.com/ldonnez/notevault/actions"><img src="https://github.com/ldonnez/notevault/actions/workflows/ci.yml/badge.svg?branch=main" alt="Build Status"></a>
<a href="http://github.com/ldonnez/notevault/releases"><img src="https://img.shields.io/github/v/tag/ldonnez/notevault" alt="Version"></a>
<a href="https://github.com/ldonnez/notevault?tab=MIT-1-ov-file#readme"><img src="https://img.shields.io/github/license/ldonnez/notevault" alt="License"></a>

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
  - [Install with a single command](#install-with-a-single-command)
  - [Install with Git](#install-with-git)
- [License](#License)

## Requirements

- GPG
- gpg-agent
- tar
- git

## Installation

### Install with a single command:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ldonnez/notevault/main/install.sh)
```

### Install with Git:

Clone the repo and run the install script:

```bash
git clone https://github.com/ldonnez/notevault.git
bash install.sh
```

This will:

- Download the latest release from Github.
- Install the nv script into `$HOME/.local/bin`

**Ensure ~/.local/bin is in your $PATH**!

## [License](LICENSE)

MIT License

Copyright (c) 2025 Lenny Donnez
