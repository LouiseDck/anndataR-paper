library(bench)
library(schard)
library(SummarizedExperiment)

data_dir  <- "runtime_benchmark/data"
out_dir   <- "runtime_benchmark"
n_cells   <- c(100, 1000, 10000, 100000, 250000, 500000)
filenames <- file.path(data_dir, paste0("d", sprintf("%d", n_cells), ".h5ad"))
min_iter  <- 3

# Force full materialisation: sum all non-zero values of the X sparse matrix.
read_and_force <- function(fn) {
  sce <- schard::h5ad2sce(fn)
  sum(assay(sce, "X")@x)
  invisible(sce)
}

# Warm up
message("Warming up schard ...")
invisible(read_and_force(filenames[[1]]))

results <- mapply(function(fn, n) {
  message("  n_cells = ", n)
  gc(verbose = FALSE)
  bm <- bench::mark(read_and_force(fn),
                    min_iterations = min_iter,
                    memory         = TRUE,
                    filter_gc      = FALSE)
  times <- as.numeric(bm$time[[1]])
  data.frame(
    package   = "schard",
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
write.csv(timings, file.path(out_dir, "timings_schard.csv"), row.names = FALSE)
message("Saved timings_schard.csv")
