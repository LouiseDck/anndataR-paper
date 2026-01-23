library(anndataR)
library(SingleCellExperiment)
library(SeuratObject)

x_options <- c(
    "integer_matrix", "integer_csparse", "integer_rsparse",
    "float_matrix", "float_csparse", "float_rsparse",
    "float_matrix_nas", "float_csparse_nas", "float_rsparse_nas"
)

################################################
# 1. Investigate reading and converting X
################################################
for (x_opt in x_options) {
    filename <- paste0("dummy_data/dummy_x_", x_opt, ".h5ad")
    ad <- anndataR::read_h5ad(filename)
    print(paste("Represented in R", x_opt))
    print(ad$X[1:5, 1:7])
    print("Converted to SCE:")
    sce <- ad$as_SingleCellExperiment()
    print(assays(sce))
    print(assay(sce, "X")[1:5, 1:7])
    print("Converted to Seurat:")
    seu <- ad$as_Seurat()
    print(seu$RNA$X[1:5, 1:7])
    print("-----")
}

# ANNDATAR | X | OK
# ANNDATAR | colnames | OK
# ANNDATAR | rownames | OK

################################################
# 2. Investigate reading and converting complete AnnData file
################################################

adata <- anndataR::read_h5ad("functionality_test/dummy_data/dummy_complete.h5ad")

sce <- adata$as_SingleCellExperiment()
seu <- adata$as_Seurat()
# 3d layers not supported in sce and seu
adata$layers$float_matrix_3d <- NULL
adata$layers$integer_matrix_3d <- NULL

sce <- adata$as_SingleCellExperiment()

orig_obsm <- adata$obsm
adata$obsm$integer_matrix_3d <- NULL
adata$obsm$float_matrix_3d <- NULL
adata$obsp$integer_matrix_3d <- NULL
adata$obsp$float_matrix_3d <- NULL
seu <- adata$as_Seurat()


# obs & var
colData(sce)
rowData(sce)
seu[[]]
seu$RNA[[]]

# ANNDATAR | obs & var | OK

# layers
assays(sce)
seu@assays
# 3D layers are not supported

# obsm & varm
# ensure data has right shape
new_varm <- lapply(adata$varm, function(mat) {
    if (length(dim(mat)) == 3) {
        mat[, 1:10 ,]
    } else{
        mat[, 1:10]
    }
})
adata$varm <- new_varm

# SCE mapping
adata$obsm <- orig_obsm
reduc_options <- c(x_options, "integer_matrix_3d", "float_matrix_3d")
rd_maps <- lapply(reduc_options, function(x_opt) {
    c(
        sampleFactors = paste0(x_opt),
        featureLoadings = paste0(x_opt)
    )
})
names(rd_maps) <- reduc_options
sce_obsmvarm <- adata$as_SingleCellExperiment(reducedDims_mapping = rd_maps)

reducedDims(sce_obsmvarm)
# anndataR does not allow a dataframe in obsm and varm
# does it allow it only in obsm?

rd_maps[["dataframe"]] <- c("sampleFactors" = "dataframe")
sce_obsmvarm_df <- adata$as_SingleCellExperiment(reducedDims_mapping = rd_maps)
# it does work

# Seurat mapping
rd_maps_seu <- lapply(x_options, function(x_opt) {
    c(
        key = paste0(x_opt, "_"),
        embeddings = paste0(x_opt),
        loadings = paste0(x_opt)
    )
})
names(rd_maps_seu) <- x_options
seu_obsmvarm <- adata$as_Seurat(reduction_mapping = rd_maps_seu)

# but 3d matrices are not supported in Seurat reductions
seu_obsmvarm[["integer_matrix_3d"]] <- CreateDimReducObject(
    embeddings = adata$obsm$integer_matrix_3d,
    key = "integer_matrix_3d_",
    loadings = NULL,
    assay = "RNA"
)
# neither are dataframes
seu_obsmvarm[["dataframe"]] <- CreateDimReducObject(
    embeddings = as.matrix(adata$obsm$dataframe),
    key = "dataframe_",
    loadings = NULL,
    assay = "RNA"
)

# ANNDATAR | SCE | obsm | OK
# ANNDATAR | SCE | varm | dataframe | unsupported
# ANNDATAR | SCE | varm | rest | OK
# ANNDATAR | Seurat | obsm & varm | dataframe | unsupported
# ANNDATAR | Seurat | obsm & varm | {integer,float}_matrix_3d | unsupported
# ANNDATAR | Seurat | obsm & varm | rest | OK

# obsp & varp
adata <- anndataR::read_h5ad("functionality_test/dummy_data/dummy_complete.h5ad")

adata$layers$float_matrix_3d <- NULL
adata$layers$integer_matrix_3d <- NULL

sce <- adata$as_SingleCellExperiment()

adata$obsm$integer_matrix_3d <- NULL
adata$obsm$float_matrix_3d <- NULL
adata$obsp$integer_matrix_3d <- NULL
adata$obsp$float_matrix_3d <- NULL
seu <- adata$as_Seurat()

colPairs(sce)
rowPairs(sce)
seu@graphs
# 3d matrices are not converted for Seurat
# ANNDATAR | obsp & varp | SCE | OK
# ANNDATAR | obsp & varp | Seurat | {integer/float}_matrix_3d | unsupported
# ANNDATAR | obsp & varp | Seurat | rest | OK

# uns
metadata(sce)
metadata(sce)$none
names(metadata(sce))
# none is present here, with value NULL

seu@misc
seu@misc$none
names(seu@misc)
# here, none is not present at all
# assigning NULL to a misc slot removes the entry --> unsupported
# ANNDATAR | uns | SCE | OK
# ANNDATAR | uns | Seurat | None | unsupported
# ANNDATAR | uns | Seurat | rest | OK