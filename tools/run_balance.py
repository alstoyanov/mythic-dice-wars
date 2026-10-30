"""Measures the balance of the pantheons and gods: plays many wars between computer players in parallel
(tests/balance_sim.gd), then writes docs/power_ranking.md (tools/balance_report.py).

    python tools/run_balance.py [--duels 60000] [--ffa 20000] [--procs 14] [--godot <exe>] [--data <folder>]
    python tools/run_balance.py --report-only        (only rewrite the report from the data already played)

The wars' results are kept as CSV files outside the project (Godot would try to import them), by default
in <temp>/mythic_dice_wars_balance. About 12 minutes for the defaults on a 16-thread computer.
"""
import argparse
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GODOT = Path(r"C:/Users/Alexander/Documents/Godot/ide/Godot_v4.7.2-stable_win64_console.exe")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--duels", type=int, default=60000)
    ap.add_argument("--ffa", type=int, default=20000, help="four-player wars")
    ap.add_argument("--procs", type=int, default=14)
    ap.add_argument("--godot", type=Path, default=GODOT)
    ap.add_argument("--data", type=Path, default=Path(tempfile.gettempdir()) / "mythic_dice_wars_balance")
    ap.add_argument("--report-only", action="store_true")
    args = ap.parse_args()
    args.data.mkdir(parents=True, exist_ok=True)
    if not args.report_only:
        for old in args.data.glob("*.csv"):
            old.unlink()
        # Split the processes between the modes by the time their wars take (a four-player war ~1.6x a duel).
        work = {"duel": args.duels, "ffa": args.ffa}
        cost = {"duel": 1.0, "ffa": 1.6}
        total = sum(work[m] * cost[m] for m in work)
        procs = []
        for mode in work:
            if work[mode] <= 0:
                continue
            n = max(1, round(args.procs * work[mode] * cost[mode] / total))
            for k in range(n):
                games = work[mode] // n + (1 if k < work[mode] % n else 0)
                out = args.data / f"{mode}_{k}.csv"
                seed = (1 if mode == "duel" else 500) + k
                cmd = [str(args.godot), "--headless", "--path", str(ROOT), "-s", "res://tests/balance_sim.gd", "--",
                       f"--mode={mode}", f"--games={games}", f"--seed={seed}", f"--out={out}"]
                procs.append(subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL))
        print(f"playing {args.duels} duels and {args.ffa} four-player wars in {len(procs)} processes...")
        t0 = time.time()
        for p in procs:
            p.wait()
        print(f"played in {time.time() - t0:.0f} s")
    subprocess.run([sys.executable, str(ROOT / "tools" / "balance_report.py"), str(args.data)], check=True)


if __name__ == "__main__":
    main()
