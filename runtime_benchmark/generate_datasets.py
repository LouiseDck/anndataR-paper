import anndata as ad
import dummy_anndata as da
import scipy as sp

def generate_dataset(n_obs, n_vars, density=0.05):
    x_mtx = sp.sparse.random(
        n_obs,
        n_vars,
        density=density,
        format="csr",
        dtype="float32"
    )

    dataset = da.generate_dataset(
        n_obs=n_obs,
        n_vars=n_vars,
        x_type = None,
        layer_types = [],
        obs_types = ["integer_array", "dense_array"],
        var_types = ["integer_array", "dense_array"],
        obsm_types = [],
        varm_types = [],
        obsp_types = [],
        varp_types = [],
        uns_types = [],
        nested_uns_types = []
    )
    dataset.X = x_mtx
    return dataset

def generate_huge_sparse(n_obs, n_vars, density=0.05):
    # split in 10 parts
    n_parts = 10
    n_obs_per_part = n_obs // n_parts

    dataset = sp.sparse.random(n_obs_per_part, n_vars, density=density, format="csr", dtype="float32")

    for i in range(n_parts - 1):
        print(f"Generating part {i + 2} of {n_parts}")
        part = sp.sparse.random(n_obs_per_part, n_vars, density=density, format="csr", dtype="float32")
        dataset = sp.sparse.vstack([dataset, part], format="csc")
        print(f"Part {i + 2} generated, current shape: {dataset.shape}")

    return dataset

# d100 = generate_dataset(100, 20000)
# d100.write_h5ad("runtime_benchmark/data/d100.h5ad")

# print("Generated d100.h5ad")

# d1000 = generate_dataset(1000, 20000)
# d1000.write_h5ad("runtime_benchmark/data/d1000.h5ad")

# print("Generated d1000.h5ad")

# d10000 = generate_dataset(10000, 20000)
# d10000.write_h5ad("runtime_benchmark/data/d10000.h5ad")

# print("Generated d10000.h5ad")

# d100000 = generate_dataset(100000, 20000)
# d100000.write_h5ad("runtime_benchmark/data/d100000.h5ad")

print("Generated d100000.h5ad")

half_huge = generate_huge_sparse(250000, 20000)
print("Generated 250000")
d250000 = da.generate_dataset(
    n_obs=250000,
    n_vars=20000,
    x_type=None,
    layer_types=[],
    obs_types=["integer_array", "dense_array"],
    var_types=["integer_array", "dense_array"],
    obsm_types=[],
    varm_types=[],
    obsp_types=[],
    varp_types=[],
    uns_types=[],
    nested_uns_types=[]
)
d250000.X = half_huge
d250000.write_h5ad("runtime_benchmark/data/d250000.h5ad")

print("Generated d250000.h5ad")

# huge_x = generate_huge_sparse(500000, 20000)

# print("Generated huge sparse matrix with shape:")
# print(huge_x.shape)
# dataset = da.generate_dataset(
#     n_obs=500000,
#     n_vars=20000,
#     x_type=None,
#     layer_types=[],
#     obs_types=["integer_array", "dense_array"],
#     var_types=["integer_array", "dense_array"],
#     obsm_types=[],
#     varm_types=[],
#     obsp_types=[],
#     varp_types=[],
#     uns_types=[],
#     nested_uns_types=[]
# )
# dataset.X = huge_x
# dataset.write_h5ad("runtime_benchmark/data/d500000.h5ad")