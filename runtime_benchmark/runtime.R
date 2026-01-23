library(anndataR)

filenames <- c(
    "runtime_benchmark/data/d100.h5ad",
    "runtime_benchmark/data/d1000.h5ad",
    "runtime_benchmark/data/d10000.h5ad",
    "runtime_benchmark/data/d100000.h5ad",
    "runtime_benchmark/data/d500000.h5ad"
)

rownames <- c("d100", "d1000", "d10000", "d100000", "d500000")

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

library(zellkonverter)

times_zk <- lapply(filenames, function(fn) {
    print(paste0("Started file ", fn))
    system.time(ad <- zellkonverter::readH5AD(fn, reader = "R"))
})

user_zk <- sapply(times_zk, function(t) t[[1]])
elapsed_zk <- sapply(times_zk, function(t) t[[3]])

times_zk2 <- lapply(filenames, function(fn) {
    print(paste0("Started file ", fn))
    system.time(ad <- zellkonverter::readH5AD(fn))
})

user_zk2 <- sapply(times_zk2, function(t) t[[1]])
elapsed_zk2 <- sapply(times_zk2, function(t) t[[3]])

timings_noschard <- data.frame(
    user = c(user_adR, user_zk, user_zk2),
    elapsed = c(elapsed_adR, elapsed_zk, elapsed_zk2),
    dataset = rep(rownames, 3),
    package = c(rep("anndataR", 5), rep("zellkonverter (R)", 5), rep("zellkonverter (basilisk)", 5))
)
timings_noschard

write.csv(timings_noschard, "runtime_benchmark/timings_noschard.csv")

library(schard)

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
    package = rep("schard", 5)
)

timings <- rbind(timings_noschard, schard_df)
write.csv(timings, "runtime_benchmark/timings.csv")

library(ggplot2)

timings <- read.csv("runtime_benchmark/timings.csv")

p1 <- ggplot(
    data = timings, 
    aes(x = dataset, y = user, group = package, color = package)
) + 
geom_point() +
geom_line()

ggsave( "runtime_benchmark/user_time.png", p1)

p2 <- ggplot(
    data = timings, 
    aes(x = dataset, y = elapsed, group = package, color = package)
) + 
geom_point() +
geom_line()
p2

ggsave("runtime_benchmark/elapsed_time.png", p2)
