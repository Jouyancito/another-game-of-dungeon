"""Drive domain-context-router.ps1 through prompts that must and must not fire it.

The point of this suite is that a context router is only worth what its aim is
worth. A skill's declared "trigger automatico" is not a mechanism -- the model
decides, silently, and you never learn when it decided wrong. A hook fires
deterministically, so its aim can be measured, and this file is the measurement.

Every new domain added to .claude/domains.json ships its cases here in the same
commit: at least one prompt that must load it and one near-miss that must not.

    python .claude/hooks/tests/test_domain_router.py
"""
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
# .claude/hooks/tests -> .claude/hooks -> .claude -> project root
PROJECT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
HOOK = os.path.join(PROJECT, ".claude", "hooks", "domain-context-router.ps1")

# (name, prompt, expected skills loaded -- empty set means the hook must stay silent)
CASES = [
    # ---- vegetation: must fire -------------------------------------------
    ("V1 build the missing shade species",
     "construi la especie de arbol tolerante a la sombra que falta en la pradera",
     {"dp-vegetation"}),
    ("V2 rebuild the grass",
     "hay que rehacer el pasto, las briznas se ven repetidas",
     {"dp-vegetation"}),
    ("V3 new dry-zone bush",
     "genera un arbusto nuevo para la zona seca del mapa",
     {"dp-vegetation"}),
    ("V4 autumn canopy, accented prompt",
     "modelá un árbol de copa ancha con color otoñal",
     {"dp-vegetation"}),
    ("V5 english phrasing",
     "add a shade-tolerant tree species to the prairie scatter",
     {"dp-vegetation"}),

    # ---- must NOT fire ----------------------------------------------------
    # The confirmed false positive: Joan's 2026-08-08 prompt about how context
    # loading should work. It names mobs and vegetacion but asks for neither.
    ("N1 meta talk about context loading (real false positive)",
     "si vamos a trabajar en los mobs, ahi recien deberia abrirse el contexto de que "
     "debe tener cada mob, como deberia crearse. pasaria lo mismo con la vegetacion",
     set()),
    ("N2 unrelated code bug",
     "arregla el bug de gold_drop.gd, tira Array vs Array[String] en cada pickup",
     set()),
    ("N3 status question, no work verb",
     "como viene el proyecto, donde estabamos",
     set()),
    ("N4 documenting the domain is not working on it",
     "documenta como funciona el scatter de vegetacion en el readme",
     set()),
    ("N5 plain git request",
     "commitea los cambios y pusheá",
     set()),
    ("N6 domain named with no work intent",
     "cuantas especies de arbol quedaron despues de la purga?",
     set()),
    # A domain listed in domains.json whose skill does not exist yet must stay
    # inert -- the router never announces context that is not on disk.
    ("N7 unbuilt domain stays inert",
     "modela un golem nuevo para el piso 1",
     set()),
]


def run(prompt):
    """Return the set of skills the hook asked to load for this prompt."""
    payload = json.dumps({"prompt": prompt, "cwd": PROJECT})
    env = dict(os.environ, CLAUDE_PROJECT_DIR=PROJECT)
    p = subprocess.run(
        ["powershell", "-ExecutionPolicy", "Bypass", "-NoProfile", "-File", HOOK],
        input=payload, capture_output=True, text=True, timeout=30, env=env,
    )
    out = p.stdout.strip()
    if not out:
        return set(), p.stderr.strip()
    try:
        ctx = json.loads(out)["hookSpecificOutput"]["additionalContext"]
    except Exception:
        return {"<unparseable: %s>" % out[:80]}, p.stderr.strip()
    known = ("dp-vegetation", "dp-mobs", "dp-boss", "dp-terrain", "dp-vfx")
    return {s for s in known if s in ctx}, p.stderr.strip()


fails = 0
for name, prompt, want in CASES:
    got, err = run(prompt)
    ok = got == want
    fails += 0 if ok else 1
    print(("PASS " if ok else "FAIL ") + name)
    if not ok:
        print("        want %s, got %s" % (sorted(want) or "silence",
                                           sorted(got) or "silence"))
    if err:
        print("        stderr: " + err[:200])

print("\n%d/%d passed" % (len(CASES) - fails, len(CASES)))
sys.exit(1 if fails else 0)
