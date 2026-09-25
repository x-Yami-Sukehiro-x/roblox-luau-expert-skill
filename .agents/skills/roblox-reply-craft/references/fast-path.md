# Fast path: from request to files

The shortest correct route for the requests that come up most. Read the row's
files in order and stop reading once the answer can be written. Two lookups
and one check run replace most of the reading.

```bash
python tools/py/recipe.py T2 M4 H3 fly      # the rows, the calls, the files to paste
node tools/bin/check-file.mjs Final.luau     # every file-level check at once
python tools/py/check_file.py Final.luau     # the same where there is no Node
```

| Request | Read, in order | Then |
|---|---|---|
| fly, noclip, speed, jump, ESP, teleport, anti-AFK, fullbright | `roblox-executor-features/SKILL.md`, `recipe.py <feature>` | paste the asset, change constants only |
| a hub with picked codes ("T2, M4, N4") | `recipe.py <codes>`, `roblox-ui/references/build-order.md` | paste each listed recipe once |
| a hub, no picks yet | `roblox-request-intake/references/visual-choices.md` | the one grouped question, or the defaults |
| a tooltip, hint or slider number | `roblox-ui-tooltips/SKILL.md`, `recipe.py H1 H3` | paste `tooltips.luau` |
| an error message pasted | the router's symptom row, then that one reference | fix the layer the error names |
| a decompiled dump pasted | `dump_index.py --feature`, `feature-search.md`, `source-to-api.md` | only FOUND builds |
| a game script to fix | the script, then the reference for the failing layer | `check-file.mjs --compare old new` |
| saving data | `roblox-data-persistence/SKILL.md` | |
| lag or climbing memory | `roblox-performance/SKILL.md` | |
| remotes, "others can't see it" | `roblox-networking/SKILL.md` | |

A common request needs at most three reference files before writing. More
than that means the router row was skipped.

## Where the time goes

| Time sink | Instead |
|---|---|
| opening a whole pack for one style | `recipe.py <code>` prints the row and the file |
| eight checks run one after another | `check-file.mjs` runs them together in about a second |
| writing a component from nothing | paste the tested recipe or asset |
| a first draft, then "an improved version" | work it out, write the file once |
| a clarifying question with a default available | decide, state the default, build |
| re-reading a reference already in context | use what was read |
| a long preamble and a closing summary | one line, the code, where it goes |

## In a custom GPT

Unzip the archive once, then run the same tools with Code Interpreter:
`python tools/py/recipe.py T2 M4` and `python tools/py/check_file.py Final.luau`.
Name the files and sections read in the reply, once.
