"""
Generate synthetic H5AD benchmark datasets.

Skips files that already exist so the script is safe to re-run.
"""

import os
import anndata as ad
import dummy_anndata as da
import scipy as sp


OUT_DIR = "runtime_benchmark/datasets"
os.makedirs(OUT_DIR, exist_ok=True)

# TODO: reenable larger sizes
SIZES = [100, 200, 500, 1_000, 2_000, 5_000, 10_000, 20_000, 50_000, 100_000] #, 200_000, 500_000, 1_000_000]
N_VARS = 20_000
DENSITY = 0.05


def _obs_var_kwargs(n_obs, n_vars):
    return dict(
        n_obs=n_obs,
        n_vars=n_vars,
        x_type=None,
        layer_types=[],
        obs_types=["integer_array", "dense_array"],
        var_types=["integer_array", "dense_array"],
        obsm_types=[],
        varm_types=[],
        obsp_types=[],
        varp_types=[],
        uns_types=[],
        nested_uns_types=[],
    )


def generate_sparse_x(n_obs, n_vars, density=DENSITY, chunk_size=50_000):
    """Build a CSC sparse matrix in chunks to avoid peak-memory spikes."""
    if n_obs <= chunk_size:
        return sp.sparse.random(n_obs, n_vars, density=density,
                                format="csr", dtype="float32")

    chunks = []
    remaining = n_obs
    while remaining > 0:
        rows = min(chunk_size, remaining)
        chunks.append(
            sp.sparse.random(rows, n_vars, density=density,
                             format="csr", dtype="float32")
        )
        remaining -= rows
        print(f"  generated {n_obs - remaining:,} / {n_obs:,} rows")
    return sp.sparse.vstack(chunks, format="csc")


def generate_and_save(n_obs, n_vars=N_VARS):
    path = os.path.join(OUT_DIR, f"d{n_obs}.h5ad")
    if os.path.exists(path):
        print(f"Skipping {path} (already exists)")
        return

    print(f"Generating d{n_obs}.h5ad ...")
    dataset = da.generate_dataset(**_obs_var_kwargs(n_obs, n_vars))
    dataset.X = generate_sparse_x(n_obs, n_vars)
    dataset.uns["x_sum"] = float(dataset.X.data.sum())
    dataset.write_h5ad(path)
    print(f"  Saved {path} (x_sum={dataset.uns['x_sum']:.0f})")


if __name__ == "__main__":
    for n in SIZES:
        generate_and_save(n)
    print("Done.")
