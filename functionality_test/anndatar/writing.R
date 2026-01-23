library(anndataR)

adata <- anndataR::read_h5ad("functionality_test/dummy_data/dummy_complete.h5ad")
adata$write_h5ad("functionality_test/anndatar/writing_back/adr_written_complete.h5ad", mode = "w")
# issue --> where exactly?

keep_slot <- function(adata, slot_names, to_keep) {
    slots <- c("obs", "var", "obsm", "varm", "obsp", "varp", "layers", "uns")
    for (slot in slots) {
        if (!(slot %in% slot_names)) {
            adata[[slot]] <- NULL
        }
    }
    return(adata)
}

keep_write <- function(slot_names, filename) {
    adata <- anndataR::read_h5ad("functionality_test/dummy_data/dummy_complete.h5ad")
    adata_subset <- keep_slot(adata, slot_names)
    adata_subset$write_h5ad(filename, mode = "w")
}

keep_write(c("obs"), "functionality_test/anndatar/writing_back/adr_written_obs.h5ad")
keep_write(c("var"), "functionality_test/anndatar/writing_back/adr_written_var.h5ad")
keep_write(c("obsm"), "functionality_test/anndatar/writing_back/adr_written_obsm.h5ad")
keep_write(c("varm"), "functionality_test/anndatar/writing_back/adr_written_varm.h5ad")
keep_write(c("obsp"), "functionality_test/anndatar/writing_back/adr_written_obsp.h5ad")
keep_write(c("varp"), "functionality_test/anndatar/writing_back/adr_written_varp.h5ad")
keep_write(c("layers"), "functionality_test/anndatar/writing_back/adr_written_layers.h5ad")
keep_write(c("uns"), "functionality_test/anndatar/writing_back/adr_written_uns.h5ad")

# check if everything except obsm and varm can be read in python
keep_write(
    c("obs", "var", "obsp", "varp", "layers", "uns"),
    "functionality_test/anndatar/writing_back/adr_written_no_obsmvarm.h5ad"
)

adata <- anndataR::read_h5ad("functionality_test/dummy_data/dummy_complete.h5ad")
# remove dataframe from obsm and varm
adata$obsm$dataframe <- NULL
adata$varm$dataframe <- NULL

# --> issue is that f$obsm$dataframe$_index goes from "Cell000" etc to "1", "2", ...
# fix: write dataframe back decently
# also for varm
adata$write_h5ad("functionality_test/anndatar/writing_back/adr_written_no_df.h5ad", mode = "w")
