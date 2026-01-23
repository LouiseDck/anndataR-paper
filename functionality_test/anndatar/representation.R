library(anndataR)

x_options <- c(
    "integer_matrix", "integer_csparse", "integer_rsparse",
    "float_matrix", "float_csparse", "float_rsparse",
    "float_matrix_nas", "float_csparse_nas", "float_rsparse_nas"
)

for (x_opt in x_options) {
    filename <- paste0("functionality_test/dummy_data/dummy_x_", x_opt, ".h5ad")
    ad <- anndataR::read_h5ad(filename)
    print(paste("Represented in R", x_opt))
    print(ad$X[1:5, 1:7])
    print("-----")
}

adata <- anndataR::read_h5ad("functionality_test/dummy_data/dummy_complete.h5ad")
adata

# Everything gets represented in R as expected:
# ANNDATAR | in R | OK