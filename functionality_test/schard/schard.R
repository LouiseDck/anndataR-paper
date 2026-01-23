library(schard)
library(SingleCellExperiment)
library(SeuratObject)

################################################
# 1. Investigate reading and converting X
################################################

x_options <- c(
    "integer_matrix", "integer_csparse", "integer_rsparse",
    "float_matrix", "float_csparse", "float_rsparse",
    "float_matrix_nas", "float_csparse_nas", "float_rsparse_nas"
)

for (x_opt in x_options) {
    filename <- paste0("functionality_test/dummy_data/dummy_x_", x_opt, ".h5ad")
    schard_sce <- schard::h5ad2sce(filename)
    print(paste("Converted x option:", x_opt))
    print(assays(schard_sce))
    print(assay(schard_sce, "X")[1:5, 1:7])
    print("-----")
}

for (x_opt in x_options) {
    filename <- paste0("functionality_test/dummy_data/dummy_x_", x_opt, ".h5ad")
    schard_seu <- schard::h5ad2seurat(filename)
    print(paste("Converted x option:", x_opt))
    print(schard_seu$RNA$data[1:5, 1:7])
    print("-----")
}

# This all works as expected.
# SCHARD | X | OK
# SCHARD | colnames | OK
# SCHARD | rownames | OK

################################################
# 2. Investigate reading and converting complete AnnData file
################################################

schard_sce_complete <- schard::h5ad2sce("functionality_test/dummy_data/dummy_complete.h5ad")
schard_seu_complete <- schard::h5ad2seurat("functionality_test/dummy_data/dummy_complete.h5ad")
# issues --> lets try a version without dataframe in obsm
schard_sce_no_obsmvarm <- schard::h5ad2sce("functionality_test/dummy_data/dummy_complete_no_df.h5ad")
schard_seu_no_obsmvarm <- schard::h5ad2seurat("functionality_test/dummy_data/dummy_complete_no_df.h5ad")
# issues --> lets try a version without 3d matrices in obsm
schard_sce <- schard::h5ad2sce("functionality_test/dummy_data/dummy_complete_no_3d.h5ad")
schard_seu <- schard::h5ad2seurat("functionality_test/dummy_data/dummy_complete_no_3d.h5ad")
# SCHARD | obsm | integer_matrix_3d | FAIL
# SCHARD | obsm | float_matrix_3d | FAIL
# SCHARD | obsm | dataframe | FAIL
# success: what got actually converted?

# overview
schard_sce
schard_seu

# layers
assays(schard_sce)
schard_seu@assays
# None got converted
# SCHARD | layers | FAIL

# obs & var
colData(schard_sce)
rowData(schard_sce)
schard_seu[[]]
schard_seu$RNA[[]]
# everything got converted, but half of it weirdly
# SCHARD | obs & var | categorical_{ordered/missing_values/ordered_missing_values} | PARTIAL FAIL (wrong type)
# SCHARD | obs & var | nullable_{integer/boolean}_array | PARTIAL FAIL (wrong type)
# SCHARD | obs & var | {string/dense/integer/boolean}_array | OK

# obsm & varm
reducedDims(schard_sce)
schard_seu@reductions
# only the dense 2d matrices got converted
# SCHARD | obsm | {integer/float}_matrix_{nas} | OK
# SCHARD | obsm | {integer/float}_{c/r}sparse_{nas} | FAIL
# SCHARD | varm | FAIL

# obsp & varp
rowPairs(schard_sce)
colPairs(schard_sce)
schard_seu@graphs
# SCHARD | obsp & varp | FAIL

# uns
metadata(schard_sce)
schard_seu@misc
# SCHARD | uns | FAIL

