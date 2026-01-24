filenames <- c(
    "runtime_benchmark/data/d100.h5ad",
    "runtime_benchmark/data/d1000.h5ad",
    "runtime_benchmark/data/d10000.h5ad",
    "runtime_benchmark/data/d100000.h5ad",
    "runtime_benchmark/data/d250000.h5ad",
    "runtime_benchmark/data/d500000.h5ad"
)

rownames <- c("100", "1000", "10000", "100000", "250000", "500000")
rownames_int <- c(100, 1000, 10000, 100000, 250000, 500000)

library(zellkonverter)

times_zk2 <- lapply(filenames, function(fn) {
    print(paste0("Started file ", fn))
    system.time(ad <- zellkonverter::readH5AD(fn))
})

user_zk2 <- sapply(times_zk2, function(t) t[[1]])
elapsed_zk2 <- sapply(times_zk2, function(t) t[[3]])

times_zk <- lapply(filenames, function(fn) {
    print(paste0("Started file ", fn))
    system.time(ad <- zellkonverter::readH5AD(fn, reader = "R"))
})

user_zk <- sapply(times_zk, function(t) t[[1]])
elapsed_zk <- sapply(times_zk, function(t) t[[3]])

library(anndataR)

times_adR <- lapply(filenames, function(fn) {
    print(paste0("Started file ", fn))
    system.time(ad <- anndataR::read_h5ad(fn))
})
user_adR <- sapply(times_adR, function(t) t[[1]])
elapsed_adR <- sapply(times_adR, function(t) t[[3]])

adR_user_elapsed <- data.frame(
    user = user_adR,
    elapsed = elapsed_adR,
    row.names = rownames
)

timings_noschard <- data.frame(
    user = c(user_adR, user_zk, user_zk2),
    elapsed = c(elapsed_adR, elapsed_zk, elapsed_zk2),
    dataset = rep(rownames, 3),
    package = c(rep("anndataR", length(rownames)), rep("zellkonverter (R)", length(rownames)), rep("zellkonverter (basilisk)", length(rownames)))
)
timings_noschard

write.csv(timings_noschard, "runtime_benchmark/timings_noschard.csv", row.names = FALSE)

library(schard)

# some sort of setup the first time this is ran as well
times_schard <- lapply(filenames, function(fn) {
    print(paste0("Started file ", fn))
    system.time(sce <- schard::h5ad2sce(fn))
})

user_schard = sapply(times_schard, function(t) t[[1]])
elapsed_schard = sapply(times_schard, function(t) t[[3]])

schard_df <- data.frame(
    user = user_schard,
    elapsed = elapsed_schard,
    dataset = rownames,
    package = rep("schard", length(rownames))
)

timings_noschard <- read.csv("runtime_benchmark/timings_noschard.csv")

timings <- rbind(timings_noschard, schard_df)
write.csv(timings, "runtime_benchmark/timings.csv", row.names = FALSE)

library(ggplot2)

timings <- read.csv("runtime_benchmark/timings.csv")

timings[["dataset"]] <- rep(rownames_int, 4)
timings[["package"]] <- c(rep("anndataR", length(rownames)), rep("zellkonverter (R)", length(rownames)), rep("zellkonverter (python)", length(rownames)), rep("schard", length(rownames)))

p1 <- ggplot(
    data = timings, 
    aes(x = dataset, y = elapsed, group = package, color = package, fill = package)
) + 
geom_point(size = 1) +
geom_line() + 
labs(
    y = "Elapsed time (in seconds)",
    x = "Number of cells in dataset",
    title = "Runtime comparison",
    subtitle = "Reading H5AD file"
) +
theme_bw()
p1

ggsave("runtime_benchmark/elapsed_time.png", p1, width = 7, height = 5)
ggsave("runtime_benchmark/elapsed_time.svg", p1, width = 7, height = 5)

p2 <- ggplot(
    data = timings, 
    aes(x = dataset, y = user, group = package, color = package, fill = package)
) + 
geom_point(size = 1) +
geom_line() + 
labs(
    y = "User time (in seconds)",
    x = "Number of cells in dataset",
    title = "Runtime comparison",
    subtitle = "Reading H5AD file"
) +
theme_bw()
p2

ggsave("runtime_benchmark/user_time.png", p2, width = 7, height = 5)
ggsave("runtime_benchmark/user_time.svg", p2, width = 7, height = 5)
