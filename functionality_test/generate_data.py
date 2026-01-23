import dummy_anndata as da

n_obs = 10
n_var = 20

# 1. generate all possible x types
no_x = ["float_matrix_3d", "integer_matrix_3d"]

x_types_all = da.matrix_generators.keys()
x_types = [x for x in x_types_all if x not in no_x]

for x in x_types:
    dummy = da.generate_dataset(
        n_obs=n_obs,
        n_vars=n_var,
        x_type = x
    )
    del dummy.layers
    del dummy.obsm
    del dummy.varm
    del dummy.obsp
    del dummy.varp
    del dummy.uns
    dummy.write_h5ad(f"functionality_test/dummy_data/dummy_x_{x}.h5ad")

# 2. generate complete dataset
dummy = da.generate_dataset(
    n_obs=n_obs,
    n_vars=n_var,
    x_type = "integer_matrix"
)
dummy.write_h5ad(f"functionality_test/dummy_data/dummy_complete.h5ad")

# for SCHARD:
# no dataframe in obsm and varm
del dummy.obsm["dataframe"]
dummy.write_h5ad(f"functionality_test/dummy_data/dummy_complete_no_df.h5ad")
# no 3d matrices in obsm
del dummy.obsm["float_matrix_3d"]
del dummy.obsm["integer_matrix_3d"]
dummy.write_h5ad(f"functionality_test/dummy_data/dummy_complete_no_3d.h5ad")

# for ZELLKONVERTER:
# no 3d matrices in varm
dummy = da.generate_dataset(
    n_obs=n_obs,
    n_vars=n_var,
    x_type = "integer_matrix"
)
del dummy.varm["integer_matrix_3d"]
del dummy.varm["float_matrix_3d"]
dummy.write_h5ad(f"functionality_test/dummy_data/dummy_varmno3d.h5ad")

# obs changes
del dummy.obsp["integer_matrix"]
del dummy.obsp["integer_matrix_3d"]
del dummy.obsp["float_matrix"]
del dummy.obsp["float_matrix_3d"]
del dummy.obsp["float_matrix_nas"]
dummy.write_h5ad(f"functionality_test/dummy_data/dummy_obsp.h5ad")

# rowPairs changes
del dummy.varp["float_matrix"]
del dummy.varp["float_matrix_3d"]
del dummy.varp["integer_matrix"]
del dummy.varp["integer_matrix_3d"]
del dummy.varp["float_matrix_nas"]
dummy.write_h5ad(f"functionality_test/dummy_data/dummy_varp.h5ad")

del dummy.uns["none"]
del dummy.uns["nested"]["none"]
dummy.write_h5ad(f"functionality_test/dummy_data/dummy_uns.h5ad")