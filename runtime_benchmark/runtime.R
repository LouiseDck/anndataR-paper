# Orchestrator: run each per-package benchmark script in a fresh Rscript
# subprocess, then combine results and plot.
#
# Each bench_*.R script is fully self-contained, loads only its own package,
# and writes its own timings CSV. Running as separate subprocesses avoids any
# shared reticulate/basilisk or R state.

out_dir <- "runtime_benchmark"

bench_scripts <- c(
  "runtime_benchmark/bench_anndataR.R",
  "runtime_benchmark/bench_zellkonverter_R.R",
  "runtime_benchmark/bench_zellkonverter_python.R",
  "runtime_benchmark/bench_schard.R"
)

for (script in bench_scripts) {
  message("\n========================================")
  message("Running: ", script)
  message("========================================")
  ret <- system2("Rscript", args = script)
  if (ret != 0L) {
    warning("Script exited with code ", ret, ": ", script)
  }
}

# --- Combine CSVs ------------------------------------------------------------

csv_files <- file.path(out_dir, c(
  "timings_anndataR.csv",
  "timings_zellkonverter_R.csv",
  "timings_zellkonverter_python.csv",
  "timings_schard.csv"
))

timings <- do.call(rbind, lapply(csv_files, function(f) {
  if (!file.exists(f)) {
    warning("Missing: ", f, " — skipping")
    return(NULL)
  }
  read.csv(f)
}))

write.csv(timings, file.path(out_dir, "timings.csv"), row.names = FALSE)
message("Saved combined timings to: ", file.path(out_dir, "timings.csv"))

# --- Plot --------------------------------------------------------------------

library(ggplot2)
library(scales)

timings <- read.csv(file.path(out_dir, "timings.csv"))

p <- ggplot(
  data = timings[!is.na(timings$median), ],
  aes(x = n_cells, y = median,
      ymin = q1, ymax = q3,
      group = package, color = package, fill = package)
) +
  geom_ribbon(alpha = 0.15, color = NA) +
  geom_line() +
  geom_point(size = 1.5) +
  scale_x_log10(labels = label_number(scale_cut = cut_short_scale())) +
  scale_y_log10(labels = label_number(suffix = " s")) +
  labs(
    x     = "Number of cells",
    y     = "Elapsed time (median \u00b1 IQR)",
    color = "Package",
    fill  = "Package",
    title = "Runtime comparison: reading H5AD files"
  ) +
  theme_bw()

p

ggsave(file.path(out_dir, "elapsed_time.pdf"), p, width = 7, height = 4)
ggsave(file.path(out_dir, "elapsed_time.png"), p, width = 7, height = 4, dpi = 300)
ggsave(file.path(out_dir, "elapsed_time.svg"), p, width = 7, height = 4)

message("Plots saved to: ", out_dir)
