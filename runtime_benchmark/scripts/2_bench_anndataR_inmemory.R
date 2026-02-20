library(bench)
library(anndataR)

data_dir  <- "runtime_benchmark/datasets"
out_dir   <- "runtime_benchmark/timings"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

n_cells   <- c(100, 200, 500, 1000, 2000, 5000, 10000, 20000, 50000, 100000, 200000, 500000)
filenames <- file.path(data_dir, paste0("d", sprintf("%d", n_cells), ".h5ad"))
min_iter  <- 3

# Force full materialisation: sum all non-zero values of the X sparse matrix.
read_and_force <- function(fn) {
  ad <- anndataR::read_h5ad(fn, as = "InMemoryAnnData")
  sum(ad$X@x)
  invisible(ad)
}

# Warm up
message("Warming up anndataR (InMemoryAnnData) ...")
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
    package   = "anndataR (InMemory)",
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
write.csv(timings, file.path(out_dir, "anndataR_inmemory.csv"), row.names = FALSE)
message("Saved ", file.path(out_dir, "anndataR_inmemory.csv"))
