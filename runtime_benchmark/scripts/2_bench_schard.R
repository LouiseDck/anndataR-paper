library(bench)
library(schard)
library(optparse)

# --- Argument parsing -------------------------------------------------------
opt <- parse_args(OptionParser(
  description = "Benchmark schard reader",
  option_list = list(
    make_option("--mode", type = "character", default = "sce",
                metavar = "MODE",
                help = "Output format: sce (SingleCellExperiment) or list [default: %default]")
  )
))
mode  <- tolower(opt$mode)
valid <- c("sce", "list")
if (!mode %in% valid) stop("--mode must be one of: ", paste(valid, collapse = ", "))

# --- Shared setup -----------------------------------------------------------
data_dir  <- "runtime_benchmark/datasets"
out_dir   <- "runtime_benchmark/timings"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

filenames <- sort(list.files(data_dir, pattern = "^d[0-9]+\\.h5ad$", full.names = TRUE))
if (length(filenames) == 0L) stop("No datasets found in ", data_dir)
n_cells   <- as.integer(sub("^d([0-9]+)\\.h5ad$", "\\1", basename(filenames)))
min_iter  <- 3

# --- Mode-specific setup ----------------------------------------------------
if (mode == "sce") {
  library(SummarizedExperiment)
  read_and_force <- function(fn) {
    sce <- schard::h5ad2sce(fn)
    sum(assay(sce, "X")@x)
  }
  pkg_label <- "schard (SCE)"
  out_file  <- "schard_sce.csv"

} else if (mode == "list") {
  read_and_force <- function(fn) {
    res <- schard::h5ad2list(fn)
    sum(res$X@x)
  }
  pkg_label <- "schard (list)"
  out_file  <- "schard_list.csv"
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
