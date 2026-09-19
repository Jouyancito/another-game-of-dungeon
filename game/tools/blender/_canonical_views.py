"""_canonical_views -- THE judgement view set, defined once, imported by all.

Why this module exists (2026-08-25 review, mejora P4). The rule "orbit the
asset, including the ungrateful angles" lived as a COPY inside each judgement
script, and copies drift: `preview_zone.py` carried the from-below view with a
comment explaining exactly why ("where floating objects reveal their gap"),
and `_turtle_shell_zone.py` -- written a day later -- dropped it. The
underside of the turtle then shipped as a blank balloon with an open gap, and
the first person able to see it was Joan, orbiting the mob himself in Godot.

A judgement set that cannot see the floor of the model APPROVES the floor of
the model. So the set lives here, once, and a script that must diverge calls
`require_views()` on its own list -- which fails the build if an ungrateful
angle went missing, instead of shipping a blind spot silently.

Each view carries its reason. The reasons are the point: they are what made
`preview_zone.py` keep its `bajo` while a reasonless copy lost it.
"""
from __future__ import annotations

# label, azimuth (0 = front, +90 = the model's left), elevation, framing mult.
# The framing multiplier is for orbit-style scripts; fixed-radius scripts may
# ignore it.
VIEWS = [
    ("cenital", 0, 89, 1.00),       # layout errors: symmetry, leg directions
    ("tresq_alto", 40, 45, 1.00),   # the flattering view -- and the baseline
    ("perfil", 90, 8, 1.00),        # where anything protruding shows
    ("frente", 0, 12, 1.00),        # face and stance
    ("atras", 180, 25, 1.00),       # where glued-on geometry separates
    ("macro_placa", 35, 55, 0.34),  # one surface region, close: does detail read?
    ("bajo", 25, -55, 1.00),        # THE UNGRATEFUL ANGLE: undersides, open
                                    # gaps, floating parts. Dropped once, and
                                    # a blank underside shipped. Never again.
]

# The angles a custom set may NOT lose, whatever else it changes. `bajo` is
# here because losing it already cost a defect; `perfil` because protrusion
# only shows there; a top view because leg-direction bugs only show there.
_REQUIRED = ("perfil", "bajo")
_REQUIRED_ANY = (("cenital", "alto"),      # at least one top-ish view
                 ("tresq", "tresq_alto"))  # at least one three-quarter


def require_views(views) -> None:
    """Fail loudly if a judgement set lost an ungrateful angle.

    `views` is any iterable whose items start with a label string. Call it at
    import/main time in every script that defines its own list instead of
    using VIEWS directly.
    """
    labels = {v[0] for v in views}
    missing = [r for r in _REQUIRED if r not in labels]
    for group in _REQUIRED_ANY:
        if not any(any(lbl == g or lbl.startswith(g) for lbl in labels)
                   for g in group):
            missing.append(" o ".join(group))
    if missing:
        raise SystemExit(
            "_canonical_views: judgement set is missing ungrateful angle(s): "
            "%s. A set that cannot see them approves what they would show. "
            "Use _canonical_views.VIEWS, or add the missing views."
            % ", ".join(missing))
