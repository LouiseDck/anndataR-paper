# Combine per-package timing CSVs and generate plots.

library(ggplot2)
library(scales)

timings_dir <- "runtime_benchmark/timings"
plots_dir   <- "runtime_benchmark/plots"
dir.create(plots_dir, showWarnings = FALSE, recursive = TRUE)

# --- Combine CSVs ------------------------------------------------------------

csv_files <- list.files(timings_dir, pattern = "\\.csv$", full.names = TRUE)

if (length(csv_files) == 0) {
  stop("No CSV files found in ", timings_dir)
}

timings <- do.call(rbind, lapply(csv_files, function(f) {
  message("Reading: ", f)
  read.csv(f)
}))

combined_path <- file.path(timings_dir, "timings.csv")
write.csv(timings, combined_path, row.names = FALSE)
message("Saved combined timings to: ", combined_path)

# --- Plot --------------------------------------------------------------------

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

ggsave(file.path(plots_dir, "elapsed_time.pdf"), p, width = 7, height = 4)
ggsave(file.path(plots_dir, "elapsed_time.png"), p, width = 7, height = 4, dpi = 300)
ggsave(file.path(plots_dir, "elapsed_time.svg"), p, width = 7, height = 4)

message("Plots saved to: ", plots_dir)
