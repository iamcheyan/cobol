# GnuCOBOL Build Workflow and cobol.nvim

`cobol.nvim` brings GnuCOBOL syntax checks, build commands, and run commands into Neovim. The COBOL compiler remains responsible for final syntax checks and program generation; the plugin runs commands configured for the project and displays their results in the editor.

## Common GnuCOBOL Commands

| Command | Purpose |
|---|---|
| `cobc -fsyntax-only INPUTCSV.COB` | Check syntax only |
| `cobc -x -o INPUTCSV INPUTCSV.COB` | Compile and link an executable |
| `cobc -I copy ...` | Specify a Copybook search directory |

## Standalone Example Workflow

Run these commands from the repository root:

```sh
make -C extensions/standalone-examples check
make -C extensions/standalone-examples run-csv
```

`check` checks all four standalone programs. `run-csv` compiles and runs `INPUTCSV.COB`, reads `input.txt`, and creates `output.csv`. The examples’ Makefile also provides `run-fixed`, `run-table`, `run-report`, and `clean`.

![Example of COBOL project structure folding](images/folding.png)

The screenshot shows native folding and summaries for Divisions, Sections, Paragraphs, and data items. Native folding does not create folds for IF/EVALUATE control blocks; if another fold provider creates them, the plugin can provide structural summaries.

## Run Commands from Neovim

In a COBOL buffer:

- `:CobolLint` or `<leader>cl`: run a GnuCOBOL syntax check immediately.
- `:CobolBuild`: run the project’s build command, or use `cobc` for a single file.
- `:CobolRun`: run the program configured for the project; if there is a build target but no run entry, the plugin will not guess the executable name.
- `:CobolTest`: run the project’s test command or perform a single-file syntax check.

Project commands are read from the `commands` section of `.cobol.json` or from Makefile targets. Save the current buffer before running them, because project build commands read files from disk. Commands are passed as argument arrays and are not run through a shell. If there is no Makefile or profile, single-file builds and runs try to use `cobc`.

Example project configuration:

```json
{
  "compiler": "cobc",
  "source_format": "fixed",
  "copybook_paths": ["copy", "cpy"],
  "commands": {
    "build": ["make", "build"],
    "run": ["make", "run"],
    "test": ["make", "test"]
  }
}
```

For more profile options, see `:help cobol-projects`.
