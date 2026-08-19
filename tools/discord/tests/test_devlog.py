"""Sanity harness for parse_devlog — the two rules that make a devlog postable.

A devlog entry is a PUBLIC claim about the game, so the parser refuses to hand
over anything that cannot be checked: an entry needs an '@ ' line saying where to
see it in a running build, and a checkbox that only a human ticks. Both rules are
the kind that break silently — a parser that quietly accepts an unticked entry
looks exactly like one that works, right up until it posts.

So each rule is tested in BOTH directions: a well-formed entry must pass, and the
same entry with the rule violated must fail. A test that only checks the happy
path cannot tell a working gate from a missing one.

    python tools/discord/tests/test_devlog.py
"""
import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dp_discord import parse_devlog, render_devlog  # noqa: E402

GOOD = """## [x] Trees stopped shimmering
Turn the camera fast and the leaves hold still now.
@ stand in front of a group of trees and spin the camera.
> TAA enabled in the renderer.
"""

results = []


def check(name, got, want):
    ok = got == want
    results.append(ok)
    print("%-4s %-52s got %-22r want %r" % ("OK" if ok else "FAIL", name, got, want))


def parse(text):
    """Parse `text`, returning entries or the string 'REJECTED'."""
    fd, path = tempfile.mkstemp(suffix=".md", text=True)
    with os.fdopen(fd, "w", encoding="utf-8") as fh:
        fh.write(text)
    try:
        return parse_devlog(path)
    except SystemExit:
        return "REJECTED"
    finally:
        os.unlink(path)


print("-- a well-formed entry parses, so the harness can see a pass --")
entries = parse(GOOD)
check("well-formed entry is accepted", entries != "REJECTED", True)
check("one entry parsed", len(entries), 1)
check("checkbox [x] reads as approved", entries[0]["approved"], True)
check("title drops the checkbox", entries[0]["title"], "Trees stopped shimmering")
check("'@ ' line lands in where", entries[0]["where"].startswith("stand in front"), True)
check("'>' line lands in tech", entries[0]["tech"], "TAA enabled in the renderer.")

print()
print("-- the '@ ' rule: an unverifiable entry must be refused --")
check("entry with no '@ ' line is REJECTED", parse(GOOD.replace("@ stand", "stand")), "REJECTED")

print()
print("-- the checkbox rule: a heading with no box is refused --")
check("heading without [ ] is REJECTED", parse(GOOD.replace("## [x] ", "## ")), "REJECTED")

print()
print("-- an unticked entry parses, but does not count as approved --")
pending = parse(GOOD.replace("[x]", "[ ]"))
check("unticked entry still parses", pending != "REJECTED", True)
check("unticked entry is NOT approved", pending[0]["approved"], False)

print()
print("-- a title with no body is refused --")
check("body-less entry is REJECTED",
      parse("## [x] Title only\n@ somewhere in the build.\n"), "REJECTED")

print()
print("-- rendering keeps both halves --")
rendered = render_devlog(entries[0])
check("rendered text carries the plain line", "hold still now" in rendered, True)
check("rendered text labels where to look", "Dónde verlo" in rendered, True)

print()
print("=" * 66)
print("  %d/%d passed" % (sum(results), len(results)))
sys.exit(0 if all(results) else 1)
