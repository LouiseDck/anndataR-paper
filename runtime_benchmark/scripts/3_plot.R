# Combine per-package timing CSVs and generate plots.

library(ggplot2)
library(ggrepel)
library(scales)

timings_dir <- "runtime_benchmark/timings"
plots_dir   <- "runtime_benchmark/plots"
dir.create(plots_dir, showWarnings = FALSE, recursive = TRUE)

final <- TRUE

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

# --- Colour palette ----------------------------------------------------------
# 4 method families; shades within each family.

pkg_colours <- c(
  "anndataR (InMemory)"          = "#155da4",
  "anndataR (InMemory to SCE)"   = "#6baed6",
  "anndataR (HDF5)"              = "#107237",
  "anndataR (HDF5 to SCE)"       = "#74c476",
  "anndataR (Reticulate)"        = "#c61717",
  "anndataR (Reticulate to SCE)" = "#e19e9e",
  "zellkonverter (R)"            = "#a63603",
  "zellkonverter (Python)"       = "#fd8d3c",
  "schard (SCE)"                 = "#54278f",
  "schard (list)"                = "#9e9ac8",
  "anndata (memory)"             = "#252525",
  "anndata (backed)"             = "#969696"
)

# --- Plot --------------------------------------------------------------------

plot_data  <- timings[!is.na(timings$median), ]

if (final) {
  # subset results, remove 'anndata .*', 'anndataR (.* to SCE)', 'schard (SCE)'
  plot_data <- plot_data[!grepl("anndata \\(.*\\)|anndataR \\(.* to SCE\\)|schard \\(SCE\\)", plot_data$package), ]
}

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
  labs(
    x     = "Number of cells",
    y     = "Elapsed time (median)",
    color = "Package",
    title = "Runtime comparison: reading H5AD files"
  ) +
  theme_bw() +
  theme(legend.position = "none")

if (final) {
  p <- p + scale_color_brewer(palette = "Dark2")
} else {
  p <- p + scale_color_manual(values = pkg_colours)
}

ggsave(file.path(plots_dir, "elapsed_time.pdf"), p, width = 9, height = 5)
ggsave(file.path(plots_dir, "elapsed_time.png"), p, width = 9, height = 5, dpi = 300)
ggsave(file.path(plots_dir, "elapsed_time.svg"), p, width = 9, height = 5)

# --- Memory usage plot -------------------------------------------------------

# Drop packages with no R memory tracking (Python benchmarks report 0)
mem_data <- plot_data[!is.na(plot_data$mem_alloc) & plot_data$mem_alloc > 0, ]

if (nrow(mem_data) > 0) {
  last_mem <- do.call(rbind, lapply(
    split(mem_data, mem_data$package),
    function(d) d[which.max(d$n_cells), ]
  ))

  p_mem <- ggplot(
    data = mem_data,
    aes(x = n_cells, y = mem_alloc, group = package, color = package)
  ) +
    geom_line() +
    geom_point(size = 1.5) +
    geom_text_repel(
      data          = last_mem,
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
    scale_y_log10(labels = label_bytes(units = "auto_binary")) +
    labs(
      x     = "Number of cells",
      y     = "Memory allocated",
      color = "Package",
      title = "Memory usage comparison: reading H5AD files"
    ) +
    theme_bw() +
    theme(legend.position = "none")

  if (final) {
    p_mem <- p_mem + scale_color_brewer(palette = "Dark2")
  } else {
    p_mem <- p_mem + scale_color_manual(values = pkg_colours)
  }

  ggsave(file.path(plots_dir, "memory_usage.pdf"), p_mem, width = 9, height = 5)
  ggsave(file.path(plots_dir, "memory_usage.png"), p_mem, width = 9, height = 5, dpi = 300)
  ggsave(file.path(plots_dir, "memory_usage.svg"), p_mem, width = 9, height = 5)
  message("Memory plots saved.")
}

message("Plots saved to: ", plots_dir)
