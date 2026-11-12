# RollWinner

RollWinner announces the winner of a World of Warcraft: Forever Beta `/roll` roll-off.

## Install

Copy the repository folder into the beta client's `Interface/AddOns` directory as `RollWinner`, then enable it from the AddOns screen. The repository intentionally stays outside the game installation.

The TOC currently targets interface `16001`, based on the installed beta build `1.60.1.70009`. Confirm the live value in the client with `/dump (select(4, GetBuildInfo()))` before testing after a client update.

## Commands

- `/rw start <min>-<max>` starts a roll-off and accepts matching rolls in the inclusive range.
- `/rw finish` announces the highest roll and clears the active roll-off.
- `/rw group` uses raid, instance, or party chat based on the current group.
- `/rw say` announces in `SAY`.
- `/rw yell` announces in `YELL`.
- `/rw raid` announces in `RAID`.
- `/rw channel <channel-number>` announces in a numbered channel.

Each character's first matching roll counts; later matching rolls from that name are ignored. Ties list players in roll-arrival order. With no group, the default group mode prints the result locally. Explicit chat modes report unavailable or rejected sends instead of silently changing channels.

Roll-result parsing uses the client’s localized `RANDOM_ROLL_RESULT` format rather than an English message.

## Development

Install Lua and Luacheck with Homebrew if they are not already available:

```sh
brew install lua luacheck
luacheck RollWinner.lua
lua -e 'assert(loadfile("RollWinner.lua"))'
```

The addon has no saved settings or GUI.

## Releases

Pushing a `v*` tag (for example `git tag v1.0.0 && git push origin v1.0.0`) runs `.github/workflows/release.yml`, which lints the addon and uses the BigWigs packager to build the zip, write the tag into the TOC's `@project-version@`, and attach it to a GitHub release. It also uploads to CurseForge, Wago, and WoWInterface for each site whose project ID is in `RollWinner.toc` (`X-Curse-Project-ID`, `X-Wago-ID`, `X-WoWI-ID`) and whose token secret (`CF_API_KEY`, `WAGO_API_TOKEN`, `WOWI_API_TOKEN`) is set. Update `CHANGELOG.md` before tagging.

To build the same zip locally, run `./build.sh -v 1.0.0`, adding `-a "<AddOns path>"` to install it as well.
