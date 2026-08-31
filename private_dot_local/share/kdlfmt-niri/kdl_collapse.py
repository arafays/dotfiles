#!/usr/bin/env python3
"""Post-processor for kdlfmt output, tuned for niri window-manager configs.

Reads kdlfmt-formatted KDL on stdin and writes a more compact, readable
version to stdout:

1. Single-statement nodes are collapsed onto one line:

       Mod+Return {
           spawn "kitty"
       }

   becomes:

       Mod+Return { spawn "kitty"; }

   Nodes whose body spans several statements or contains nested blocks
   (input, layout, touchpad, ...) are left expanded.

2. One-liners are aligned as a table, within each block:

   - the first argument of every node starts in the same column;
   - every opening `{` sits in the same column to the right of that.

       Mod+E        hotkey-overlay-title="Files" { spawn "nautilus"; }
       Mod+Space    hotkey-overlay-title="Launcher" { spawn "fuzzel"; }

   Lines whose brace anchor would fall inside a quoted string (braces in
   arguments, e.g. `spawn-sh "sh -c 'echo {}'"`) are left untouched.

3. Standalone `//` comment lines are re-indented to the depth of the
   block they live in (kdlfmt preserves their original column, which
   leaves stray indents behind after hand edits).

4. Blank lines are inserted to separate logical sections:

   - between top-level nodes of different kinds; consecutive nodes of the
     same kind (e.g. several `spawn-at-startup`) stay grouped;
   - before `//` comment lines at any depth, since a comment usually
     starts a new section (e.g. inside `binds`).

The script is a line-based heuristic over already-valid kdlfmt output —
it is not a KDL parser and cannot fix broken syntax.

Usage:
    kdlfmt-niri < config.kdl
    kdlfmt format --kdl-version v1 - | python3 kdl_collapse.py

Upstream: https://github.com/Artifait/NiriConfigFormatter
"""

import re
import sys

# A single-statement node, as emitted by kdlfmt:
#
#     indent   header {
#     +indent      body          <- exactly one line, no braces
#     indent   }
#
# The closing brace must sit at the same indent as the header line
# (backreference \1), which is what keeps multi-line blocks safe.
SINGLE_STATEMENT_NODE = re.compile(
    r"^([ \t]*)(\S.*?)\s*\{\n"  # opening line: "header {"
    r"[ \t]*([^\n{}]+?)[ \t]*\n"  # one body line without braces
    r"\1\}$",  # closing "}" at the header's indent
    re.MULTILINE,
)

# A one-liner in the final text: "indent header { body }". The header part
# may not contain braces so that brace characters inside quoted arguments
# can never be mistaken for the structural opening brace.
ONE_LINER_NODE = re.compile(r"^([ \t]*)([^{}]*\S)[ \t]+(\{ .+ \})$")

# A commented-out one-liner: "indent // header { body }". It joins the
# alignment table of its block, with the `//` marker counted as indent,
# so commented-out binds line up with the real ones.
COMMENT_ONE_LINER = re.compile(r"^([ \t]*)(//[ \t]*)([^{}]*\S)[ \t]+(\{ .+ \})$")

# Collapsing an inner node can turn its parent into a single-statement
# node as well, so keep collapsing until the text stops changing.
MAX_COLLAPSE_PASSES = 10

BLOCK_HEADER = re.compile(r"\{\s*$")  # a line that opens a block
BLOCK_CLOSE = re.compile(r"^[ \t]*\}$")  # a line that closes one

INDENT_UNIT = "    "  # indent added per nesting level (kdlfmt default: 4)


def node_kind(line: str) -> str:
    """First word of a node line — the key used to group top-level siblings."""
    return re.split(r'[\s"]', line.strip(), maxsplit=1)[0]


def collapse_single_statement_nodes(text: str) -> str:
    """Rewrite `Name { statement }` blocks as one-liners.

    The callback normalizes the body: surrounding whitespace is stripped
    and a trailing `;` is appended unless already present.
    """

    def collapse(match: "re.Match[str]") -> str:
        indent, header, body = match.groups()
        body = body.strip()
        if not body.endswith(";"):
            body += ";"
        return f"{indent}{header} {{ {body} }}"

    for _ in range(MAX_COLLAPSE_PASSES):
        collapsed = SINGLE_STATEMENT_NODE.sub(collapse, text)
        if collapsed == text:
            break
        text = collapsed
    return text


def _brace_is_outside_strings(line: str, col: int) -> bool:
    """True if the brace at column `col` is not inside a double-quoted string."""
    return line.count('"', 0, col) % 2 == 0


def align_one_liners(text: str) -> str:
    """Align one-liners of each block as a table.

    One-liners are grouped by their enclosing block (tracked with a brace
    stack). Within a group:

    - nodes that have arguments get their first argument padded to a
      shared column (one past the longest node name that has arguments);
    - every `{` is then padded to a shared column one past the longest
      "name + arguments" run, so all braces line up as well.

    Lines whose brace anchor falls inside a quoted string are skipped
    entirely (no padding, no target contribution). Commented-out
    one-liners (`// Mod+J { ... }`) join their block's table with the
    `//` marker counted as indent. The pass is idempotent: a second run
    finds everything already in place.
    """
    lines = text.split("\n")

    def classify(line: str):
        if line.lstrip().startswith("//"):
            return None, COMMENT_ONE_LINER.match(line)
        return ONE_LINER_NODE.match(line), None

    classified = [classify(line) for line in lines]

    # Group each one-liner by the chain of blocks it sits inside. Blank
    # and comment lines never affect the stack (comments may contain
    # brace characters).
    stack: list[str] = []
    groups: dict[tuple[str, ...], list[int]] = {}
    for i, (line, (code_m, comment_m)) in enumerate(zip(lines, classified)):
        stripped = line.strip()
        if code_m or comment_m:
            groups.setdefault(tuple(stack), []).append(i)
        elif not stripped or stripped.startswith("//"):
            continue
        elif BLOCK_HEADER.search(line):
            stack.append(stripped)
        elif BLOCK_CLOSE.match(line) and stack:
            stack.pop()

    aligned = list(lines)
    for members in groups.values():
        parsed = []
        for i in members:
            code_m, comment_m = classified[i]
            if comment_m:
                indent, marker, header, tail = comment_m.groups()
                indent += marker.rstrip() + " "  # normalize `//   ` to `// `
                brace_col = comment_m.start(4)
            else:
                indent, header, tail = code_m.groups()
                brace_col = code_m.start(3)
            # Rows whose structural brace sits inside a quoted string
            # would be corrupted by padding — leave them untouched.
            if not _brace_is_outside_strings(lines[i], brace_col):
                continue
            name = re.match(r"\S+", header).group(0)
            args = header[len(name) :].strip()
            parsed.append((i, indent, name, args, tail))
        if not parsed:
            continue

        # Column where the first argument starts; only nodes that have
        # arguments vote.
        arg_cols = [
            len(indent) + len(name) + 1 for _, indent, name, args, _ in parsed if args
        ]
        arg_col = max(arg_cols) if arg_cols else None

        # End of the "name + arguments" run of each line after padding,
        # then the shared `{` column one past the longest run.
        def content_end(indent: str, name: str, args: str) -> int:
            return arg_col + len(args) if args else len(indent) + len(name)

        brace_target = (
            max(content_end(indent, name, args) for _, indent, name, args, _ in parsed)
            + 1
        )

        for i, indent, name, args, tail in parsed:
            if args:
                gap = " " * (arg_col - len(indent) - len(name))
                brace_pad = " " * (brace_target - arg_col - len(args))
                aligned[i] = f"{indent}{name}{gap}{args}{brace_pad}{tail}"
            else:
                gap = " " * (brace_target - len(indent) - len(name))
                aligned[i] = f"{indent}{name}{gap}{tail}"

    return "\n".join(aligned)


def reindent_comments(text: str) -> str:
    """Re-indent standalone `//` comment lines to their block depth.

    kdlfmt keeps comment lines at whatever column they were written at,
    so hand edits leave stray indents (` // comment` buried blocks deep).
    Every comment-only line is rebuilt as `INDENT_UNIT * depth` followed
    by the comment text. Comment lines never affect brace-depth tracking,
    even when they contain `{`/`}` characters. Block comments (`/* */`)
    and trailing comments on code lines are left alone.
    """
    lines = text.split("\n")
    out: list[str] = []
    depth = 0
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("//"):
            out.append(INDENT_UNIT * depth + stripped)
            continue
        if stripped:  # blank lines never change the depth
            depth += line.count("{") - line.count("}")
        out.append(line)
    return "\n".join(out)


def add_blank_lines(text: str) -> str:
    """Insert blank lines between logical sections.

    Two rules, in order of encounter:

    1. A top-level node (brace depth 0) gets a blank line above it when
       its kind differs from the previous top-level node's kind.
    2. A `//` comment line gets a blank line above it — unless it is the
       first line of a block (the previous line ends with `{`), directly
       follows another comment (multi-line comment blocks stay intact),
       or is already separated by a blank line.

    Comment lines never affect brace-depth tracking, even when they
    contain `{`/`}` characters.
    """
    lines = text.split("\n")
    result: list[str] = []
    depth = 0  # brace depth while scanning
    prev_kind: str | None = None  # kind of the previous top-level node

    for line in lines:
        stripped = line.strip()
        previous = (result[-1] if result else "").strip()

        if not stripped:  # keep blank lines as-is
            result.append(line)
            continue

        if stripped.startswith("//"):
            if (
                previous
                and not previous.endswith("{")
                and not previous.startswith("//")
            ):
                result.append("")
            result.append(line)
            continue

        need_blank = False

        if depth == 0:  # top-level node
            kind = node_kind(line)
            need_blank |= prev_kind is not None and kind != prev_kind and previous != ""
            prev_kind = kind

        if need_blank:
            result.append("")

        result.append(line)
        depth += line.count("{") - line.count("}")

    return "\n".join(result)


def main() -> None:
    text = sys.stdin.read()
    text = collapse_single_statement_nodes(text)
    text = align_one_liners(text)
    text = reindent_comments(text)
    text = add_blank_lines(text)
    sys.stdout.write(text)


if __name__ == "__main__":
    main()
