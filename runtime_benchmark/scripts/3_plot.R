# Combine per-package timing CSVs and generate plots.

library(ggplot2)
library(dplyr)
library(ggrepel)
library(readr)
library(purrr)
library(scales)
library(patchwork)

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

timings <- map_dfr(csv_files, read_csv) |>
  mutate(
    label = package,
    package = gsub("^(.*?)\\s*\\(.*\\)$", "\\1", label),
    approach = gsub("^.*?\\s*\\((.*)\\)$", "\\1", label)
  ) |>
  select(package, approach, label, everything())
write_csv(timings, combined_path)
message("Saved combined timings to: ", combined_path)

# --- Prepare data for plotting -----------------------------------------------
plot_data  <- timings |>
  filter(!is.na(median)) |>
  arrange(package, approach, n_cells)

if (final) {
  # subset results, remove 'anndata .*', 'anndataR (.* to SCE)', 'schard (SCE)'
  plot_data <- plot_data |>
    filter(
      package != "anndata",
      !grepl("anndataR (.* to SCE)", label),
      label != "schard (SCE)"
    )
}

# find index of approach
plot_data <- plot_data |>
  group_by(package) |>
  mutate(
    approach_num = as.character(as.numeric(factor(approach)))
  ) |>
  ungroup()

last_points <- plot_data |>
  group_by(package) |>
  slice_max(n_cells, n = 1) |>
  ungroup()

# determine unique packages and approaches for consistent coloring and shaping in the plots
legend <- plot_data |>
  select(package, approach, label, approach_num) |>
  distinct()

distict_packages <- unique(legend$package)
n_distict_packages <- length(distict_packages)
pkg_colours <- setNames(
  RColorBrewer::brewer.pal(n = n_distict_packages, name = "Dark2"),
  distict_packages
)
distinct_approaches <- unique(legend$approach_num)
n_distinct_approaches <- length(distinct_approaches)
approach_num_shapes <- setNames(c(16, 17, 15, 18, 8)[seq_len(n_distinct_approaches)], distinct_approaches)
approach_num_linetypes <- setNames(c("solid", "dashed", "dotted", "dotdash", "longdash")[seq_len(n_distinct_approaches)], distinct_approaches)

legend <- legend |>
  mutate(
    color = pkg_colours[package],
    shape = approach_num_shapes[approach_num],
    linetype = approach_num_linetypes[approach_num]
  )
manual_colors <- setNames(legend$color, legend$label)
manual_shapes <- setNames(legend$shape, legend$label)
manual_linetypes <- setNames(legend$linetype, legend$label)

# --- Elapsed time plot ------------------------------------------------------
p <- ggplot(
  data = plot_data,
  aes(
    x = n_cells,
    y = median,
    group = label,
    color = label,
    linetype = label,
    shape = label
  )
) +
  geom_line() +
  geom_point(size = 1.5) +
  scale_x_log10(
    breaks = c(100, 1e3, 1e4, 1e5, 1e6),
    labels = label_number(scale_cut = cut_short_scale())
  ) +
  scale_y_log10(
    limits = c(0.01, max(plot_data$median)),
    breaks = c(0.01, 0.1, 1, 10, 100),
    labels = label_number(suffix = " s")
  ) +
  scale_color_manual(values = manual_colors) +
  scale_shape_manual(values = manual_shapes) +
  scale_linetype_manual(values = manual_linetypes) +
  labs(
    x     = "Number of cells",
    y     = "Elapsed time (median)",
    color = "Package and approach",
    linetype = "Package and approach",
    shape = "Package and approach",
    title = "Runtime comparison"
  ) +
  theme_bw()

p

ggsave(file.path(plots_dir, "elapsed_time.pdf"), p, width = 9, height = 5)
ggsave(file.path(plots_dir, "elapsed_time.png"), p, width = 9, height = 5, dpi = 300)
ggsave(file.path(plots_dir, "elapsed_time.svg"), p, width = 9, height = 5)

# --- Memory usage plot -------------------------------------------------------

# same plot but with mem_alloc. drop packages with no memory tracking (Python benchmarks report 0)

plot_data_mem <- plot_data |>
  filter(mem_alloc > 0)

q <- ggplot(
  data = plot_data_mem,
  aes(
    x = n_cells,
    y = mem_alloc,
    group = label,
    color = label,
    linetype = label,
    shape = label
  )
) +
  geom_line() +
  geom_point(size = 1.5) +
  scale_x_log10(
    breaks = c(100, 1e3, 1e4, 1e5, 1e6),
    labels = label_number(scale_cut = cut_short_scale())
  ) +
  scale_y_log10(
    limits = c(1e6, 1e11),
    breaks = c(1e6, 1e7, 1e8, 1e9, 1e10, 1e11),
    labels = label_bytes()
  ) +
  scale_color_manual(values = manual_colors) +
  scale_shape_manual(values = manual_shapes) +
  scale_linetype_manual(values = manual_linetypes) +
  labs(
    x     = "Number of cells",
    y     = "Memory allocated (max)",
    color = "Package and approach",
    linetype = "Package and approach",
    shape = "Package and approach",
    title = "Memory usage comparison"
  ) +
  theme_bw()

q
ggsave(file.path(plots_dir, "memory_usage.pdf"), q, width = 9, height = 5)
ggsave(file.path(plots_dir, "memory_usage.png"), q, width = 9, height = 5, dpi = 300)
ggsave(file.path(plots_dir, "memory_usage.svg"), q, width = 9, height = 5)

# --- Combine plot with patchwork ---------------------------------------------

pq <- p / q + plot_layout(guides = "collect") & theme(legend.position = "bottom")

ggsave(file.path(plots_dir, "combined_plot.pdf"), pq, width = 8, height = 8)
ggsave(file.path(plots_dir, "combined_plot.png"), pq, width = 8, height = 8, dpi = 300)
ggsave(file.path(plots_dir, "combined_plot.svg"), pq, width = 8, height = 9)
