# Collect and save session / environment information for supplementary materials.
# Outputs: runtime_benchmark/session_info.txt

out_dir <- "runtime_benchmark"
out_file <- file.path(out_dir, "session_info.txt")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

lines <- character(0)
section <- function(title) {
  lines <<- c(lines, "", paste0("## ", title), strrep("-", nchar(title) + 3))
}
add <- function(...) lines <<- c(lines, paste0(...))

# ---------------------------------------------------------------------------
# Machine specs
# ---------------------------------------------------------------------------
section("Machine specifications")

# OS
os_info <- tryCatch(
  trimws(readLines("/etc/os-release")),
  error = function(e) character(0)
)
pretty_name <- grep("^PRETTY_NAME=", os_info, value = TRUE)
if (length(pretty_name)) {
  add("OS             : ", gsub('^PRETTY_NAME="?|"?$', "", pretty_name[1]))
} else {
  add(
    "OS             : ",
    Sys.info()[["sysname"]],
    " ",
    Sys.info()[["release"]]
  )
}

# CPU model
cpu_model <- tryCatch(
  {
    cpu_lines <- readLines("/proc/cpuinfo")
    mn <- grep("^model name", cpu_lines, value = TRUE)
    if (length(mn)) trimws(sub(".*:", "", mn[1])) else "unknown"
  },
  error = function(e) "unknown"
)
add("CPU model      : ", cpu_model)

# Physical cores (unique core id × physical id combos)
n_cores <- tryCatch(
  {
    cpu_lines <- readLines("/proc/cpuinfo")
    phys <- grep("^physical id", cpu_lines, value = TRUE)
    core <- grep("^core id", cpu_lines, value = TRUE)
    if (length(phys) && length(core)) {
      length(unique(paste(phys, core)))
    } else {
      as.integer(system("nproc --all", intern = TRUE))
    }
  },
  error = function(e) NA_integer_
)
add("CPU cores      : ", n_cores)

# Logical threads
n_threads <- tryCatch(
  as.integer(trimws(system("nproc --all", intern = TRUE))),
  error = function(e) NA_integer_
)
add("CPU threads    : ", n_threads)

# Total RAM (bytes → GiB)
ram_gb <- tryCatch(
  {
    mem_lines <- readLines("/proc/meminfo")
    total_kb <- as.numeric(sub(
      "MemTotal:\\s*(\\d+).*",
      "\\1",
      grep("^MemTotal:", mem_lines, value = TRUE)[1]
    ))
    round(total_kb / 1024^2, 1)
  },
  error = function(e) NA_real_
)
add("Total RAM (GiB): ", ram_gb)

# ---------------------------------------------------------------------------
# Pixi version
# ---------------------------------------------------------------------------
section("Pixi")
pixi_ver <- tryCatch(
  trimws(system("pixi --version", intern = TRUE)[1]),
  error = function(e) "not found"
)
add("pixi version: ", pixi_ver)

# ---------------------------------------------------------------------------
# R packages
# ---------------------------------------------------------------------------
section("R session info")
add(paste(capture.output(sessionInfo()), collapse = "\n"))

section("R package versions (key packages)")
r_pkgs <- c(
  "anndataR",
  "zellkonverter",
  "schard",
  "reticulate",
  "SummarizedExperiment",
  "HDF5Array",
  "rhdf5",
  "Matrix",
  "bench",
  "BiocManager",
  "ggplot2",
  "dplyr",
  "purrr",
  "readr",
  "scales",
  "patchwork",
  "ggrepel"
)
for (pkg in r_pkgs) {
  ver <- tryCatch(as.character(packageVersion(pkg)), error = function(e) {
    "not installed"
  })
  add(sprintf("  %-25s %s", pkg, ver))
}

# ---------------------------------------------------------------------------
# Python packages
# ---------------------------------------------------------------------------
section("Python package versions (key packages)")
py_script <- '
import importlib.metadata as meta
pkgs = ["anndata", "dummy-anndata", "h5py", "numpy", "scipy", "hdf5plugin"]
for p in pkgs:
    try:
        v = meta.version(p)
    except meta.PackageNotFoundError:
        v = "not installed"
    print(f"  {p:<25} {v}")
'
py_out <- tryCatch(
  system2(
    "python",
    args = c("-c", shQuote(py_script)),
    stdout = TRUE,
    stderr = FALSE
  ),
  error = function(e) "python not found"
)
add(py_out)

py_ver <- tryCatch(
  trimws(system("python --version", intern = TRUE)[1]),
  error = function(e) "not found"
)
add("")
add("Python version: ", py_ver)

# ---------------------------------------------------------------------------
# Write output
# ---------------------------------------------------------------------------
lines <- c("# Session information for anndataR benchmark", lines)
writeLines(lines, out_file)
message("Session info saved to: ", out_file)
cat(paste(lines, collapse = "\n"), "\n")
