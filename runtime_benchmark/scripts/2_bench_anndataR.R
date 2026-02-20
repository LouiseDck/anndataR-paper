library(bench)
library(anndataR)
library(optparse)

# --- Argument parsing -------------------------------------------------------
opt <- parse_args(OptionParser(
  description = "Benchmark anndataR backends",
  option_list = list(
    make_option("--backend", type = "character", default = "inmemory",
                metavar = "BACKEND",
                help = "Backend to use: inmemory, hdf5, or reticulate [default: %default]"),
    make_option("--sce", action = "store_true", default = FALSE,
                help = "Convert to SingleCellExperiment before accessing X")
  )
))
backend <- tolower(opt$backend)
to_sce  <- opt$sce
valid   <- c("inmemory", "hdf5", "reticulate")
if (!backend %in% valid) stop("--backend must be one of: ", paste(valid, collapse = ", "))

# --- Shared setup -----------------------------------------------------------
data_dir  <- "runtime_benchmark/datasets"
out_dir   <- "runtime_benchmark/timings"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

filenames <- sort(list.files(data_dir, pattern = "^d[0-9]+\\.h5ad$", full.names = TRUE))
if (length(filenames) == 0L) stop("No datasets found in ", data_dir)
n_cells   <- as.integer(sub("^d([0-9]+)\\.h5ad$", "\\1", basename(filenames)))
min_iter  <- 3

# --- Backend × mode setup ---------------------------------------------------
if (backend == "inmemory" && !to_sce) {
  read_and_force <- function(fn) {
    ad <- anndataR::read_h5ad(fn, as = "InMemoryAnnData")
    sum(ad$X@x)
  }
  pkg_label <- "anndataR (InMemory)"
  out_file  <- "anndataR_inmemory.csv"

} else if (backend == "inmemory" && to_sce) {
  library(SummarizedExperiment)
  read_and_force <- function(fn) {
    sce <- anndataR::read_h5ad(fn, as = "SingleCellExperiment")
    sum(assay(sce, "X")@x)
  }
  pkg_label <- "anndataR (InMemory to SCE)"
  out_file  <- "anndataR_inmemory2sce.csv"

} else if (backend == "hdf5" && !to_sce) {
  read_and_force <- function(fn) {
    ad <- anndataR::read_h5ad(fn, as = "HDF5AnnData")
    sum(ad$X@x)
  }
  pkg_label <- "anndataR (HDF5)"
  out_file  <- "anndataR_hdf5.csv"

} else if (backend == "hdf5" && to_sce) {
  library(SummarizedExperiment)
  read_and_force <- function(fn) {
    ad  <- anndataR::read_h5ad(fn, as = "HDF5AnnData")
    sce <- ad$as_SingleCellExperiment()
    sum(assay(sce, "X")@x)
  }
  pkg_label <- "anndataR (HDF5 to SCE)"
  out_file  <- "anndataR_hdf52sce.csv"

} else if (backend == "reticulate" && !to_sce) {
  library(reticulate)
  ad_py <- reticulate::import("anndata")
  read_and_force <- function(fn) {
    ad <- ad_py$read_h5ad(fn)
    sum(ad$X@x)
  }
  pkg_label <- "anndataR (Reticulate)"
  out_file  <- "anndataR_reticulate.csv"

} else if (backend == "reticulate" && to_sce) {
  library(reticulate)
  library(SummarizedExperiment)
  ad_py <- reticulate::import("anndata")
  read_and_force <- function(fn) {
    ad  <- ad_py$read_h5ad(fn)
    sce <- ad$as_SingleCellExperiment()
    sum(assay(sce, "X")@x)
  }
  pkg_label <- "anndataR (Reticulate to SCE)"
  out_file  <- "anndataR_reticulate2sce.csv"
}

# --- Warmup with validation -------------------------------------------------
message("Warming up ", pkg_label, " ...")
expected_sum <- as.numeric(rhdf5::h5read(filenames[[1]], "uns/x_sum"))
actual_sum   <- read_and_force(filenames[[1]])
stopifnot(abs(actual_sum - expected_sum) / max(1, abs(expected_sum)) < 1e-3)
message("  Validation OK (X sum: ", round(actual_sum), ")")

# --- Benchmark --------------------------------------------------------------
results <- mapply(function(fn, n) {
  message("  n_cells = ", n)
  gc(verbose = FALSE)
  bm <- bench::mark(read_and_force(fn),
                    min_iterations = min_iter,
                    memory         = TRUE,
                    filter_gc      = FALSE)
  times <- as.numeric(bm$time[[1]])
  data.frame(
    package   = pkg_label,
    n_cells   = n,
    median    = median(times),
    q1        = quantile(times, 0.25),
    q3        = quantile(times, 0.75),
    min_time  = min(times),
    max_time  = max(times),
    mem_alloc = as.numeric(bm$mem_alloc),
    n_itr     = length(times),
    stringsAsFactors = FALSE
  )
}, filenames, n_cells, SIMPLIFY = FALSE)

timings <- do.call(rbind, results)
write.csv(timings, file.path(out_dir, out_file), row.names = FALSE)
message("Saved ", file.path(out_dir, out_file))
