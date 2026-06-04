# Purpose
A repository for my personal AutoHotkey library.

# Directory Structure
```
README.md                        # This file
.claude/
├── settings.local.json          # Local permissions configuration
admin/                           # To-do files and VSCode workspace file
config/                          # Various settings files, mostly TableList files (TL/TLS extension, see below)
icons/                           # Icons used by various scripts
├── iconCredits.txt              # Where icons came from
source/
├── common/                      # Logic shared by all scripts
    ├── base/                    # "Base" classes that other classes derive from
        ├── arrayBase.ahk        # A special "base" class that all arrays extend ("installed" by common.ahk)
        ├── objectBase.ahk       # A special "base" class that all objects extend ("installed" by common.ahk)
        ├── stringBase.ahk       # A special "base" class that all strings extend ("installed" by common.ahk)
    ├── class/                   # Various classes used across the library
    ├── external/                # Scripts written by others
    ├── lib/                     # Libraries of static helper functions
    ├── program/                 # Classes for interacting with specific programs - these are typically (but not always) used by corresponding scripts in the source/program/ directory
    ├── static/                  # Static classes of helper functions
    ├── common.ahk               # The core of most scripts in this library - basic settings, #Include-ing everything in this directory
├── general/                     # Hotkeys that aren't specific to any one program
├── program/                     # Program-specific hotkeys. Many of these have a matching class in the common/program/ directory
├── standalone/                  # Unlike most of this repository, these scripts are NOT part of main.ahk - they are run by themselves. Some larger scripts are in their own subdirectory to group things together.
├── sub/                         # These scripts aren't directly #Include'd in main.ahk, but main.ahk does start (and reload) them alongside itself.
├── firstSetup.ahk               # A script that "installs" the library - create settings file and create a library "pointer" in the user's Documents folder
├── main.ahk                     # The core script - all other scripts (except those in standalone/) are #Include'd by this one to be run.
First Setup.lnk                  # A shortcut (relative via cmd.exe use) to the firstSetup script
```

## Sibling Repositories
There are a couple of other repositories that might appear alongside this:
* ahkPrivate/ # TableList files that I don't want to commit to this (public) repo
* ahkTest/    # Temporary testing stuff (useful stuff moves to this repo)

# TableList files (.tl/.tls)
These files are intended to be formatted (with tabs) to LOOK like a table, but also allow simple operations (add before, add after, replace, etc.) that reduce duplication. More details and examples can be found in source\common\class\tableList.ahk.
