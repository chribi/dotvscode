# Configure VS Code

## Description

This is a configuration script for VS Code, installing some extensions and configuring user settings.

## Prerequisites

* VS Code >= 1.25 installed and in $PATH
* node installed and in $PATH
* Font [Fira Code](https://github.com/tonsky/FiraCode) installed
* git-bash when using Windows

## Structure

Settings and extensions are placed in [config](./config), grouped by feature.  For each group `$group` the following files might exist

| Name                    | Description |
| ------------------------| ----------- |
| `$group-extensions.txt` | Contains a list of extensions to install for the group |
| `$group-settings.json`  | A list of settings for the group |

## Usage

After cloning and switching to the cloned directory, use the following to configure all groups:

```
./install.sh --all
```

If only some groups are needed, they can be listed:

```
./install.sh groupA groupB
```

To get a list of all groups, use

```
./install.sh --list
```

### Conflicts

The install script will use [json](http://github.com/trentm/json) to merge settings with any pre-existing settings.  The default merge behavior is to prefer the pre-existing settings.  If you want to prefer settings from this repository, add the option `--prefer-newer` to the call to `./install.sh`.

If something goes wrong, a backup of the `settings.json` is found at `tmp/settings.backup.json`.  This will be overwritten on consecutive runs of `./install.sh`, so be careful!
