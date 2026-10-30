"""Writes docs/power_ranking.md from the wars played by tests/balance_sim.gd (see tools/run_balance.py).

    python tools/balance_report.py <folder with the CSV files> [--out docs/power_ranking.md]

How strong is a god? Every war has a winner; a model gives each player a strength (their primary god's
rating + their secondary god's rating + the edge of their place in the turn order) and the chance to
win is their share of the strengths: e^u / sum of e^u over the players (for two players, the logistic
curve). The ratings that best explain who won are fitted to all the wars at once, so a god is judged
apart from the partner it came with and the opponents it met. Fitted the same way: a rating for every
pair of gods (to find pairs that are more, or less, than the sum of their gods) and for every pantheon.

A rating is shown as a win chance: a god with an average partner against an average pair in a duel
(50% = average), and in a four-player war (25% = average).

Matchups: for two gods X and Y on opposite sides of the duels, the wins of X's side are compared with
what the ratings expect (they already include both partners and the turn order). A large difference
(z: how many standard deviations) means X does better (or worse) against Y in particular.
Needs numpy and scipy.
"""
import argparse
import csv
import math
import re
from collections import defaultdict
from datetime import date
from pathlib import Path

import numpy as np
from scipy.optimize import minimize

ROOT = Path(__file__).resolve().parent.parent
RIDGE = 1.0  # a little pull towards average, so rare combinations are not over-read

# Verdicts on the spread of win chances (duel, percentage points from 50%)
FAIR = 2.0
SLIGHT = 4.0


def catalog() -> tuple[dict, dict]:
    text = (ROOT / "core" / "god_catalog.gd").read_text(encoding="utf-8")
    pantheons = {m[0]: m[1] for m in re.findall(r'\{"id": "(\w+)", "name": "([^"]+)", "realm"', text)}
    gods = {}
    for gid, pan, role, name, title in re.findall(
            r'\{"id": "(\w+)", "pantheon": "(\w+)", "role": (PRIMARY|SECONDARY), "name": "([^"]+)", "title": "([^"]+)"', text):
        gods[gid] = {"pantheon": pan, "role": role.lower(), "name": name, "title": title}
    # boon and bane texts, read entry by entry (an entry ends where the next begins)
    for chunk in re.split(r'\n\t\{"id": ', text)[1:]:
        gid = re.match(r'"(\w+)"', chunk).group(1)
        boon = re.search(r'"boon_name": "([^"]*)", "boon_text": "([^"]*)"', chunk)
        bane = re.search(r'"bane_name": "([^"]*)", "bane_text": "([^"]*)"', chunk)
        if gid in gods:
            gods[gid]["boon"] = "%s: %s" % boon.groups() if boon else ""
            gods[gid]["bane"] = "%s: %s" % bane.groups() if bane else ""
    return pantheons, gods


def load(folder: Path) -> list[dict]:
    games = []
    for f in sorted(folder.glob("*.csv")):
        with open(f, newline="", encoding="utf-8") as fh:
            for row in csv.DictReader(fh):
                w = int(row["winner"])
                if w < 0:
                    continue
                n = sum(1 for k in range(8) if f"p{k}_primary" in row)
                players = [{"pantheon": row[f"p{k}_pantheon"], "primary": row[f"p{k}_primary"],
                            "secondary": row[f"p{k}_secondary"]} for k in range(n)]
                games.append({"mode": row["mode"], "winner": w, "players": players})
    return games


class Model:
    """Win chance = softmax of the players' strengths. `key(player)` -> the rated things of a player
    (e.g. its two gods); every place in the turn order gets its own term per mode."""

    def __init__(self, games: list[dict], key, names: list[str]):
        self.names = names
        self.index = {n: i for i, n in enumerate(names)}
        self.modes = sorted({g["mode"] for g in games})
        self.pos_index = {}
        for g in games:
            for k in range(1, len(g["players"])):
                self.pos_index.setdefault((g["mode"], k), len(names) + len(self.pos_index))
        self.size = len(names) + len(self.pos_index)
        width = max(len(g["players"]) for g in games)
        self.X = np.zeros((len(games), width, self.size), dtype=np.float32)
        self.mask = np.zeros((len(games), width), dtype=bool)
        self.y = np.array([g["winner"] for g in games])
        for i, g in enumerate(games):
            for k, p in enumerate(g["players"]):
                self.mask[i, k] = True
                for item in key(p):
                    self.X[i, k, self.index[item]] += 1.0
                if k > 0:
                    self.X[i, k, self.pos_index[(g["mode"], k)]] = 1.0
        self.reg = np.zeros(self.size)
        self.reg[:len(names)] = RIDGE
        res = minimize(self._loss, np.zeros(self.size), jac=True, method="L-BFGS-B")
        self.theta = res.x
        self.p = self.chances(self.theta)
        # Approximate standard errors (the diagonal of the information matrix)
        px = np.einsum("gk,gkj->gj", self.p, self.X)
        info = np.einsum("gk,gkj->j", self.p, self.X ** 2) - (px ** 2).sum(axis=0)
        self.se = 1.0 / np.sqrt(np.maximum(info + self.reg, 1e-9))

    def chances(self, theta: np.ndarray) -> np.ndarray:
        u = np.einsum("gkj,j->gk", self.X, theta)
        u = np.where(self.mask, u, -np.inf)
        u -= u.max(axis=1, keepdims=True)
        e = np.exp(u)
        return e / e.sum(axis=1, keepdims=True)

    def _loss(self, theta: np.ndarray):
        p = self.chances(theta)
        pw = p[np.arange(len(self.y)), self.y]
        loss = -np.log(np.maximum(pw, 1e-12)).sum() + 0.5 * (self.reg * theta ** 2).sum()
        onehot = np.zeros_like(p)
        onehot[np.arange(len(self.y)), self.y] = 1.0
        grad = np.einsum("gk,gkj->j", (p - onehot), self.X) + self.reg * theta
        return loss, grad

    def rating(self, name: str) -> float:
        return float(self.theta[self.index[name]])

    def error(self, name: str) -> float:
        return float(self.se[self.index[name]])


def duel_pct(s: float) -> float:
    return 100.0 / (1.0 + math.exp(-s))


def ffa_pct(s: float) -> float:
    return 100.0 * math.exp(s) / (math.exp(s) + 3.0)


def verdict(points: float) -> str:
    a = abs(points)
    if a <= FAIR:
        return "fair"
    if a <= SLIGHT:
        return "a little strong" if points > 0 else "a little weak"
    return "**strong**" if points > 0 else "**weak**"


def center(values: dict, groups: dict) -> dict:
    """Ratings shifted so that each group (primary gods, secondary gods) averages 0."""
    out = {}
    for members in groups.values():
        m = sum(values[x] for x in members) / len(members)
        for x in members:
            out[x] = values[x] - m
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("data", type=Path)
    ap.add_argument("--out", type=Path, default=ROOT / "docs" / "power_ranking.md")
    args = ap.parse_args()
    pantheons, gods = catalog()
    games = load(args.data)
    duels = [g for g in games if g["mode"] == "duel"]
    ffas = [g for g in games if g["mode"] == "ffa"]
    god_ids = list(gods)
    roles = {"primary": [g for g in god_ids if gods[g]["role"] == "primary"],
             "secondary": [g for g in god_ids if gods[g]["role"] == "secondary"]}
    pairs = [f"{a}+{b}" for a in roles["primary"] for b in roles["secondary"] if gods[a]["pantheon"] == gods[b]["pantheon"]]
    pan_ids = list(pantheons)

    by_gods = lambda p: [p["primary"], p["secondary"]]  # noqa: E731
    by_pair = lambda p: [f'{p["primary"]}+{p["secondary"]}']  # noqa: E731
    by_pan = lambda p: [p["pantheon"]]  # noqa: E731
    fits = {}
    for label, subset in (("all", games), ("duel", duels), ("ffa", ffas)):
        if subset:
            fits[label] = {"gods": Model(subset, by_gods, god_ids), "pairs": Model(subset, by_pair, pairs),
                           "pantheons": Model(subset, by_pan, pan_ids)}

    def god_ratings(label: str) -> dict:
        m = fits[label]["gods"]
        return center({g: m.rating(g) for g in god_ids}, roles)

    def mean_centered(model: Model, items: list[str]) -> dict:
        vals = {x: model.rating(x) for x in items}
        avg = sum(vals.values()) / len(vals)
        return {x: v - avg for x, v in vals.items()}

    # Raw counts: appearances and wins per god / pair / pantheon, by mode
    raw = defaultdict(lambda: [0, 0])
    for g in games:
        for k, p in enumerate(g["players"]):
            for item in (p["primary"], p["secondary"], f'{p["primary"]}+{p["secondary"]}', p["pantheon"]):
                raw[(g["mode"], item)][0] += 1
                raw[(g["mode"], item)][1] += 1 if k == g["winner"] else 0

    def raw_pct(mode: str, item: str) -> str:
        n, w = raw[(mode, item)]
        return f"{100.0 * w / n:.1f}%" if n else "–"

    lines: list[str] = []
    w = lines.append
    w("# Power ranking of the gods")
    w("")
    w(f"*Generated {date.today().isoformat()} by `python tools/run_balance.py` (wars played by `tests/balance_sim.gd`, "
      f"analysed by `tools/balance_report.py`). Do not edit by hand: run the tool again after changing a god.*")
    w("")
    w(f"**Data:** {len(duels):,} duels (2 players) and {len(ffas):,} four-player wars between computer players "
      "(all Strategists), with the default rules: balanced turn order (head start), the secondary god waking after "
      f"a few conquests, no fog of war, a medium realm (28 territories), square and hex boards alike. Every player's "
      "pantheon and gods were drawn at random.")
    w("")
    w("**How to read it.** The ratings come from a model fitted to all the wars at once, so each god is judged "
      "apart from the partner it was paired with, the opponents it met and the turn order. A rating is shown as a "
      "win chance: a god with an *average partner* against an *average pair*, in a duel (50% is average) and in "
      "a four-player war (25% is average). **Overall** is fitted to the duels and the four-player wars together "
      "and shown as a duel win chance; the lists are in its order. *Duel* and *4 players* are fitted to each "
      "kind of war alone: where they differ, a god suits one kind better. *Raw* is the plain share of wars won "
      "(not corrected for partners and opponents). ± is the 95% margin of error. Verdicts (overall): within "
      f"±{FAIR:.0f} points of 50% *fair*, up to ±{SLIGHT:.0f} *a little strong / weak*, beyond that **strong / weak**.")
    w("")
    w("The results are what the computer players make of each god. A human may use some powers better "
      "(miracles, timing) or worse; treat them as a guide, not the last word.")
    w("")

    summary_at = len(lines)

    # Turn order
    w("## Turn order")
    w("")
    for label, name, fair in (("duel", "Duels", 50.0), ("ffa", "Four-player wars", 25.0)):
        subset = duels if label == "duel" else ffas
        if not subset:
            continue
        n = len(subset[0]["players"])
        wins = [0] * n
        for g in subset:
            wins[g["winner"]] += 1
        w(f"- **{name}:** " + ", ".join(f"#{k + 1} {100.0 * wins[k] / len(subset):.1f}%" for k in range(n))
          + f" (fair {fair:.0f}%).")
    w("")

    # Pantheons
    all_pan = mean_centered(fits["all"]["pantheons"], pan_ids)
    duel_pan = mean_centered(fits["duel"]["pantheons"], pan_ids) if "duel" in fits else all_pan
    ffa_pan = mean_centered(fits["ffa"]["pantheons"], pan_ids) if "ffa" in fits else all_pan
    spread = [duel_pct(v) - 50.0 for v in all_pan.values()]
    w("## Are the pantheons balanced?")
    w("")
    worst = max(abs(s) for s in spread)
    overall = "balanced" if worst <= FAIR else ("fairly balanced" if worst <= SLIGHT else "not balanced")
    w(f"**{overall.capitalize()}:** the pantheons' duel win chances lie between {50 + min(spread):.1f}% and "
      f"{50 + max(spread):.1f}%. A pantheon's rating is that of its six gods together, so it also tells how good "
      "its choice of gods is on average.")
    w("")
    w("| # | Pantheon | Overall | Duel | 4 players | Raw duel wins | Raw 4-player wins | Verdict |")
    w("|---|---|---|---|---|---|---|---|")
    m_all = fits["all"]["pantheons"]
    for i, pid in enumerate(sorted(pan_ids, key=lambda x: -all_pan[x]), 1):
        err = 1.96 * m_all.error(pid) * 25.0
        w(f"| {i} | {pantheons[pid]} | **{duel_pct(all_pan[pid]):.1f}%** ±{err:.1f} | {duel_pct(duel_pan[pid]):.1f}% | {ffa_pct(ffa_pan[pid]):.1f}% | "
          f"{raw_pct('duel', pid)} | {raw_pct('ffa', pid)} | {verdict(duel_pct(all_pan[pid]) - 50.0)} |")
    w("")

    # Pantheon vs pantheon
    if duels:
        m = fits["duel"]["pantheons"]
        idx = {pid: k for k, pid in enumerate(pan_ids)}
        obs = np.zeros((7, 7))
        exp = np.zeros((7, 7))
        var = np.zeros((7, 7))
        cnt = np.zeros((7, 7))
        for gi, g in enumerate(duels):
            a, b = g["players"][0]["pantheon"], g["players"][1]["pantheon"]
            if a == b:
                continue
            pa = m.p[gi, 0]
            for x, y, won, px in ((a, b, g["winner"] == 0, pa), (b, a, g["winner"] == 1, 1.0 - pa)):
                obs[idx[x], idx[y]] += won
                exp[idx[x], idx[y]] += px
                var[idx[x], idx[y]] += px * (1.0 - px)
                cnt[idx[x], idx[y]] += 1
        w("### Pantheon against pantheon (duels)")
        w("")
        w("How often the row's pantheon beat the column's. **Bold**: clearly more or less than the two pantheons' "
          "ratings expect (|z| ≥ 2.5): the row's gods suit, or struggle against, the column's in particular.")
        w("")
        w("| | " + " | ".join(pantheons[p] for p in pan_ids) + " |")
        w("|---|" + "---|" * len(pan_ids))
        for x in pan_ids:
            cells = []
            for y in pan_ids:
                i, j = idx[x], idx[y]
                if x == y or cnt[i, j] == 0:
                    cells.append("–")
                    continue
                pct = 100.0 * obs[i, j] / cnt[i, j]
                z = (obs[i, j] - exp[i, j]) / math.sqrt(max(var[i, j], 1e-9))
                cells.append(f"**{pct:.0f}%**" if abs(z) >= 2.5 else f"{pct:.0f}%")
            w(f"| **{pantheons[x]}** | " + " | ".join(cells) + " |")
        w("")

    # Gods
    all_g = god_ratings("all")
    duel_g = god_ratings("duel") if "duel" in fits else all_g
    ffa_g = god_ratings("ffa") if "ffa" in fits else all_g
    m_all = fits["all"]["gods"]
    for role, heading in (("primary", "Primary gods"), ("secondary", "Secondary gods")):
        w(f"## Power ranking: {heading.lower()}")
        w("")
        w("| # | God | Pantheon | Overall | Duel | 4 players | Raw duel wins | Raw 4-player wins | Verdict | Powers |")
        w("|---|---|---|---|---|---|---|---|---|---|")
        for i, gid in enumerate(sorted(roles[role], key=lambda x: -all_g[x]), 1):
            g = gods[gid]
            err = 1.96 * m_all.error(gid) * 25.0
            powers = g.get("boon", "") + ((" — *" + g["bane"] + "*") if g.get("bane") else "")
            w(f"| {i} | **{g['name']}** | {pantheons[g['pantheon']]} | **{duel_pct(all_g[gid]):.1f}%** ±{err:.1f} | {duel_pct(duel_g[gid]):.1f}% | "
              f"{ffa_pct(ffa_g[gid]):.1f}% | {raw_pct('duel', gid)} | {raw_pct('ffa', gid)} | "
              f"{verdict(duel_pct(all_g[gid]) - 50.0)} | {powers} |")
        w("")
    w("## All gods in one list")
    w("")
    w("Primary and secondary gods side by side (each against the average of its own kind).")
    w("")
    w("| # | God | Role | Pantheon | Overall | Duel | 4 players |")
    w("|---|---|---|---|---|---|---|")
    for i, gid in enumerate(sorted(god_ids, key=lambda x: -all_g[x]), 1):
        g = gods[gid]
        w(f"| {i} | {g['name']} | {g['role']} | {pantheons[g['pantheon']]} | **{duel_pct(all_g[gid]):.1f}%** | {duel_pct(duel_g[gid]):.1f}% | "
          f"{ffa_pct(ffa_g[gid]):.1f}% |")
    w("")

    # Pairs
    pm = fits["all"]["pairs"]
    pair_r = mean_centered(pm, pairs)
    pair_duel = mean_centered(fits["duel"]["pairs"], pairs) if "duel" in fits else pair_r
    pair_ffa = mean_centered(fits["ffa"]["pairs"], pairs) if "ffa" in fits else pair_r
    synergy = {}
    for pr in pairs:
        a, b = pr.split("+")
        synergy[pr] = pair_r[pr] - (all_g[a] + all_g[b])
    w("## Power ranking: pairs of gods")
    w("")
    w("Every primary god with every secondary god of its pantheon (63 pairs), rated as a team. **Synergy**: "
      "how much better (or worse) the pair does than its two gods' own ratings add up to, in duel win-chance "
      "points; a large synergy means the two powers help (or hinder) each other.")
    w("")
    w("| # | Pair | Pantheon | Overall | Duel | 4 players | Raw duel wins | Synergy |")
    w("|---|---|---|---|---|---|---|---|")
    for i, pr in enumerate(sorted(pairs, key=lambda x: -pair_r[x]), 1):
        a, b = pr.split("+")
        err = 1.96 * pm.error(pr) * 25.0
        syn = duel_pct(pair_r[pr]) - duel_pct(all_g[a] + all_g[b])
        w(f"| {i} | {gods[a]['name']} + {gods[b]['name']} | {pantheons[gods[a]['pantheon']]} | "
          f"**{duel_pct(pair_r[pr]):.1f}%** ±{err:.1f} | {duel_pct(pair_duel[pr]):.1f}% | {ffa_pct(pair_ffa[pr]):.1f}% | {raw_pct('duel', pr)} | "
          f"{syn:+.1f} |")
    w("")

    # Matchups between gods
    found = []
    if duels:
        m = fits["duel"]["gods"]
        obs, exp, var, cnt = defaultdict(float), defaultdict(float), defaultdict(float), defaultdict(int)
        for gi, g in enumerate(duels):
            pa = float(m.p[gi, 0])
            sides = [(g["players"][0], g["winner"] == 0, pa), (g["players"][1], g["winner"] == 1, 1.0 - pa)]
            for (me, won, px), (them, _, _) in ((sides[0], sides[1]), (sides[1], sides[0])):
                for x in (me["primary"], me["secondary"]):
                    for y in (them["primary"], them["secondary"]):
                        if x == y:
                            continue
                        obs[(x, y)] += won
                        exp[(x, y)] += px
                        var[(x, y)] += px * (1.0 - px)
                        cnt[(x, y)] += 1
        for (x, y), n in cnt.items():
            if n < 80:
                continue
            z = (obs[(x, y)] - exp[(x, y)]) / math.sqrt(max(var[(x, y)], 1e-9))
            if z >= 3.0:  # each matchup appears twice (X vs Y and Y vs X): keep the side that gains
                found.append((z, x, y, n, 100.0 * obs[(x, y)] / n, 100.0 * exp[(x, y)] / n))
        found.sort(reverse=True)
        tests = len([1 for (x, y), n in cnt.items() if n >= 80]) // 2
        w("## Counters: gods that do better against particular gods")
        w("")
        w(f"For every two gods met on opposite sides of the duels ({tests} matchups with enough wars), the wins "
          "of the first god's side are compared with what the ratings expect (they already include both "
          "partners and the turn order). Listed: the matchups where the first god's side won clearly more "
          "(z ≥ 3: three standard deviations; by chance alone about one or two of this many matchups would "
          "reach it, so a single entry near 3 is a hint, not proof).")
        w("")
        if found:
            w("| God | does better against | Wars | Won | Expected | z | Powers involved |")
            w("|---|---|---|---|---|---|---|")
            for z, x, y, n, won, ex in found[:40]:
                w(f"| **{gods[x]['name']}** ({pantheons[gods[x]['pantheon']]}) | {gods[y]['name']} "
                  f"({pantheons[gods[y]['pantheon']]}) | {n} | {won:.1f}% | {ex:.1f}% | {z:.1f} | "
                  f"{gods[x].get('boon', '').split(':')[0]} vs {(gods[y].get('bane') or gods[y].get('boon', '')).split(':')[0]} |")
        else:
            w("None: no god does clearly better against a particular god than the ratings explain. The gods' "
              "strengths add up; there are no hard counters.")
        w("")

    # Summary, placed at the top of the file
    summary: list[str] = ["## Summary", ""]
    s_add = summary.append
    pan_sorted = sorted(pan_ids, key=lambda x: -all_pan[x])
    s_add(f"- **Pantheons: {overall}.** Strongest {pantheons[pan_sorted[0]]} ({duel_pct(all_pan[pan_sorted[0]]):.1f}%), "
          f"weakest {pantheons[pan_sorted[-1]]} ({duel_pct(all_pan[pan_sorted[-1]]):.1f}%), in a duel against an "
          "average pantheon.")
    pts = {g: duel_pct(all_g[g]) - 50.0 for g in god_ids}
    fair_n = sum(1 for v in pts.values() if abs(v) <= FAIR)
    slight_n = sum(1 for v in pts.values() if FAIR < abs(v) <= SLIGHT)
    far_n = len(god_ids) - fair_n - slight_n
    s_add(f"- **Gods:** {fair_n} of {len(god_ids)} are fair (within ±{FAIR:.0f} points), {slight_n} a little off, "
          f"{far_n} far off; from {50 + min(pts.values()):.1f}% to {50 + max(pts.values()):.1f}%.")
    ranked = sorted(god_ids, key=lambda x: -all_g[x])
    name = lambda g: f"{gods[g]['name']} {duel_pct(all_g[g]):.0f}%"  # noqa: E731
    s_add("- **Strongest:** " + ", ".join(name(g) for g in ranked[:5]) + ".")
    s_add("- **Weakest:** " + ", ".join(name(g) for g in reversed(ranked[-5:])) + ".")
    if "duel" in fits and "ffa" in fits:
        diff = {g: duel_g[g] - ffa_g[g] for g in god_ids}
        duelists = [g for g in sorted(god_ids, key=lambda x: -diff[x]) if diff[g] > 0.4][:4]
        brawlers = [g for g in sorted(god_ids, key=lambda x: diff[x]) if diff[g] < -0.4][:4]
        show = lambda g: f"{gods[g]['name']} ({duel_pct(duel_g[g]):.0f}% duel, {ffa_pct(ffa_g[g]):.0f}% of 4)"  # noqa: E731
        if duelists:
            s_add("- **Better in duels than in four-player wars:** " + ", ".join(show(g) for g in duelists) + ".")
        if brawlers:
            s_add("- **Better in four-player wars than in duels:** " + ", ".join(show(g) for g in brawlers)
                  + ". Defensive powers and attack limits cost less when rivals also fight each other.")
    syn = {pr: duel_pct(pair_r[pr]) - duel_pct(all_g[pr.split('+')[0]] + all_g[pr.split('+')[1]]) for pr in pairs}
    strong_syn = [pr for pr in sorted(pairs, key=lambda x: -abs(syn[x])) if abs(syn[pr]) >= 5.0]
    if strong_syn:
        s_add("- **Pairs that are more (or less) than their gods:** " + ", ".join(
            f"{gods[pr.split('+')[0]]['name']} + {gods[pr.split('+')[1]]['name']} {syn[pr]:+.0f}" for pr in strong_syn[:6])
            + " points (a pair's margin of error is about ±2.5).")
    best = max(pairs, key=lambda x: pair_r[x])
    worst_pair = min(pairs, key=lambda x: pair_r[x])
    s_add(f"- **Strongest pair:** {gods[best.split('+')[0]]['name']} + {gods[best.split('+')[1]]['name']} "
          f"({duel_pct(pair_r[best]):.1f}%); **weakest:** {gods[worst_pair.split('+')[0]]['name']} + "
          f"{gods[worst_pair.split('+')[1]]['name']} ({duel_pct(pair_r[worst_pair]):.1f}%).")
    if duels:
        if found:
            top = ", ".join(f"{gods[x]['name']} against {gods[y]['name']}" for _, x, y, _, _, _ in found[:3])
            s_add(f"- **Counters:** {len(found)} matchups where a god does clearly better against a particular god "
                  f"than its strength explains; the clearest: {top}.")
        else:
            s_add("- **Counters:** none clear; the gods' strengths simply add up.")
    summary.append("")
    lines[summary_at:summary_at] = summary
    args.out.write_text("\n".join(lines), encoding="utf-8")
    print("wrote", args.out, f"({len(duels)} duels, {len(ffas)} four-player wars)")


if __name__ == "__main__":
    main()
