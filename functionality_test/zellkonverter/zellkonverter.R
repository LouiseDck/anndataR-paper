library(zellkonverter)
library(SingleCellExperiment)

################################################
# 1. Investigate reading and converting X
################################################

for (x_opt in x_options) {
    print(paste("Converted x option:", x_opt))
    filename <- paste0("dummy_data/dummy_x_", x_opt, ".h5ad")
    zk_sce <- zellkonverter::readH5AD(filename, reader = "R")
    print(assays(zk_sce))
    print(assay(zk_sce, "X")[1:5, 1:7])
    print("-----")
}

# This all works as expected.
# ZELLKONVERTER | X | OK
# ZELLKONVERTER | colnames | OK
# ZELLKONVERTER | rownames | OK

################################################
# 2. Investigate reading and converting complete AnnData file to SCE
################################################

zk_sce <- zellkonverter::readH5AD("functionality_test/dummy_data/dummy_complete.h5ad", reader = "R")
# warnings, but stuff got converted

# layers
assays(zk_sce)
# ZELLKONVERTER | layers | OK

# obs & var
colData(zk_sce)
rowData(zk_sce)
# ZELLKONVERTER | obs | OK
# ZELLKONVERTER | var | OK

# obsm
# issues: not solveable
#   setting 'reducedDims' failed for 'dummy_data/dummy_complete_no_3d.h5ad':
#   invalid 'value' in 'reducedDims(<SingleCellExperiment>) <- value' each
#   element of 'value' should have number of rows equal to 'ncol(x)'
# ZELLKONVERTER | obsm | FAIL

# varm
# try without dataframe and 3d matrices in varm
zk_sce_varm <- zellkonverter::readH5AD("functionality_test/dummy_data/dummy_varmno3d.h5ad", reader = "R")
# dataframe varm failed though
# ZELLKONVERTER | varm | dataframe | FAIL
# ZELLKONVERTER | varm | integer_matrix_3d | FAIL
# ZELLKONVERTER | varm | float_matrix_3d | FAIL
# ZELLKONVERTER | varm | {integer/float}_{matrix/rsparse/csparse}_{nas} | OK

# obsp & varp
# issues with dense matrices --> only csparse and rsparse work
zk_sce_obsp <- zellkonverter::readH5AD("functionality_test/dummy_data/dummy_obsp.h5ad", reader = "R")
colPairs(zk_sce_obsp)
zk_sce_varp <- zellkonverter::readH5AD("functionality_test/dummy_data/dummy_varp.h5ad", reader = "R")
rowPairs(zk_sce_varp)
# ZELLKONVERTER | obsp & varp | {integer/float}_matrix_{nas/3d} | FAIL
# ZELLKONVERTER | obsp & varp | {integer/float}_{csparse/rsparse}_{nas} | OK

# uns
# issue with the "none" entry
zk_sce_uns <- zellkonverter::readH5AD("functionality_test/dummy_data/dummy_uns.h5ad", reader = "R")
# ZELLKONVERTER | uns | none | FAIL
# ZELLKONVERTER | uns | categoricals | OK
# ZELLKONVERTER | uns | matrices | OK
# ZELLKONVERTER | uns | scalars | OK
# ZELLKONVERTER | uns | nested | OK
# ZELLKONVERTER | uns | nan | OK
