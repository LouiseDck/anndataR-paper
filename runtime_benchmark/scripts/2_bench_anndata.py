"""
Benchmark anndata (Python) reading H5AD files.

Serves as a Python-native control; does not convert to SCE.

Modes (--backed):
  default  load fully into memory (InMemoryAnnData-equivalent)
  --backed  use backed / lazy mode (HDF5-backed, reads on access)

Outputs runtime_benchmark/timings/anndata_{memory,backed}.csv in the same
column format as the R benchmark CSVs.
"""

import argparse
import csv
import gc
import os
import re
import time

import h5py
import numpy as np
import anndata

# --- Argument parsing -------------------------------------------------------
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--backed", action="store_true",
                    help="Use backed (lazy HDF5) mode instead of in-memory")
args = parser.parse_args()

# --- Shared setup -----------------------------------------------------------
DATA_DIR  = "runtime_benchmark/datasets"
OUT_DIR   = "runtime_benchmark/timings"
os.makedirs(OUT_DIR, exist_ok=True)

_pat      = re.compile(r"^d(\d+)\.h5ad$")
filenames = sorted(
    (p for p in (os.path.join(DATA_DIR, f) for f in os.listdir(DATA_DIR)) if _pat.match(os.path.basename(p))),
    key=lambda p: int(_pat.match(os.path.basename(p)).group(1))
)
if not filenames:
    raise FileNotFoundError(f"No datasets found in {DATA_DIR}")
MIN_ITER  = 3

# --- Mode-specific setup ----------------------------------------------------
if args.backed:
    def read_and_force(fn):
        adata = anndata.read_h5ad(fn, backed="r")
        x = adata.X[:]
        return float(x.data.sum() if hasattr(x, "data") else x.sum())
    pkg_label = "anndata (backed)"
    out_file  = "anndata_backed.csv"
else:
    def read_and_force(fn):
        adata = anndata.read_h5ad(fn, backed=False)
        x = adata.X
        return float(x.data.sum() if hasattr(x, "data") else x.sum())
    pkg_label = "anndata (memory)"
    out_file  = "anndata_memory.csv"

# --- Warmup with validation -------------------------------------------------
fn0 = filenames[0]
print(f"Warming up {pkg_label} ...")
with h5py.File(fn0, "r") as f:
    expected_sum = float(f["uns"]["x_sum"][()])
actual_sum = read_and_force(fn0)
if abs(actual_sum - expected_sum) / max(1.0, abs(expected_sum)) > 1e-3:
    raise AssertionError(
        f"Validation failed: X sum mismatch (expected {expected_sum:.0f}, got {actual_sum:.0f})"
    )
print(f"  Validation OK (X sum: {actual_sum:.0f})")

# --- Benchmark --------------------------------------------------------------
results = []
for fn in filenames:
    n = int(_pat.match(os.path.basename(fn)).group(1))

    print(f"  n_cells = {n}")
    gc.collect()

    times = [None] * MIN_ITER
    for i in range(MIN_ITER):
        t0 = time.perf_counter()
        read_and_force(fn)
        times[i] = time.perf_counter() - t0

    t = np.array(times)
    results.append({
        "package":   pkg_label,
        "n_cells":   n,
        "median":    float(np.median(t)),
        "q1":        float(np.percentile(t, 25)),
        "q3":        float(np.percentile(t, 75)),
        "min_time":  float(t.min()),
        "max_time":  float(t.max()),
        "mem_alloc": 0,
        "n_itr":     len(times),
    })

out_path = os.path.join(OUT_DIR, out_file)
with open(out_path, "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=results[0].keys())
    writer.writeheader()
    writer.writerows(results)

print(f"Saved {out_path}")
