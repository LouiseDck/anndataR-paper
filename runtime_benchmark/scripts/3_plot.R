# Combine per-package timing CSVs and generate plots.

library(ggplot2)
library(ggrepel)
library(scales)

timings_dir <- "runtime_benchmark/timings"
plots_dir   <- "runtime_benchmark/plots"
dir.create(plots_dir, showWarnings = FALSE, recursive = TRUE)

# --- Combine CSVs ------------------------------------------------------------

csv_files <- list.files(timings_dir, pattern = "\\.csv$", full.names = TRUE)
# exclude the combined file itself if it already exists
csv_files <- csv_files[basename(csv_files) != "timings.csv"]

if (length(csv_files) == 0) {
  stop("No CSV files found in ", timings_dir)
}

combined_path <- file.path(timings_dir, "timings.csv")

timings <- do.call(rbind, lapply(csv_files, function(f) {
  message("Reading: ", f)
  read.csv(f)
}))
write.csv(timings, combined_path, row.names = FALSE)
message("Saved combined timings to: ", combined_path)
# timings <- read.csv(combined_path)

# --- Colour palette ----------------------------------------------------------
# 4 method families; shades within each family.

pkg_colours <- c(
  "anndataR (InMemory)"          = "#08519c",
  "anndataR (InMemory to SCE)"   = "#6baed6",
  "anndataR (HDF5)"              = "#006d2c",
  "anndataR (HDF5 to SCE)"       = "#74c476",
  "anndataR (Reticulate)"        = "#084594",
  "anndataR (Reticulate to SCE)" = "#9ecae1",
  "zellkonverter (R)"            = "#a63603",
  "zellkonverter (Python)"       = "#fd8d3c",
  "schard"                       = "#54278f",
  "anndata (memory)"             = "#252525",
  "anndata (backed)"             = "#969696"
)

# --- Plot --------------------------------------------------------------------

plot_data  <- timings[!is.na(timings$median), ]

# subset results, remove 'anndata .*', 'anndataR (.* to SCE)'.
plot_data <- plot_data[!grepl("anndata \\(.*\\)|anndataR \\(.* to SCE\\)", plot_data$package), ]

last_points <- do.call(rbind, lapply(
  split(plot_data, plot_data$package),
  function(d) d[which.max(d$n_cells), ]
))

p <- ggplot(
  data = plot_data,
  aes(x = n_cells, y = median, group = package, color = package)
) +
  geom_line() +
  geom_point(size = 1.5) +
  geom_text_repel(
    data          = last_points,
    aes(label = package),
    size          = 2.8,
    hjust         = 0,
    direction     = "y",
    nudge_x       = 0.15,
    segment.size  = 0.3,
    segment.alpha = 0.5,
    box.padding   = 0.15,
    show.legend   = FALSE
  ) +
  scale_x_log10(
    breaks = c(100, 1e3, 1e4, 1e5, 1e6),
    labels = label_number(scale_cut = cut_short_scale()),
    expand = expansion(mult = c(0.03, 0.3))
  ) +
  scale_y_log10(labels = label_number(suffix = " s")) +
  # scale_color_manual(values = pkg_colours) +
  scale_color_brewer(palette = "Dark2") +
  labs(
    x     = "Number of cells",
    y     = "Elapsed time (median)",
    color = "Package",
    title = "Runtime comparison: reading H5AD files"
  ) +
  theme_bw() +
  theme(legend.position = "none")

ggsave(file.path(plots_dir, "elapsed_time.pdf"), p, width = 9, height = 5)
ggsave(file.path(plots_dir, "elapsed_time.png"), p, width = 9, height = 5, dpi = 300)
ggsave(file.path(plots_dir, "elapsed_time.svg"), p, width = 9, height = 5)

message("Plots saved to: ", plots_dir)
