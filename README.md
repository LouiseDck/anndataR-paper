# anndataR paper

This repository contains the code to reproduce the analyses performed in the associated paper, 
as well as the associated paper.

## Paper
The `paper` subdirectory contains the source files, images and generated pdf's for the anndata 
paper and the supplementary material.

## Runtime benchmarks
In order to investigate the runtime performance of anndataR, we generated several dummy datasets
of different sizes, each with 5% density.
We check how fast [schard](https://github.com/cellgeni/schard), 
[zellkonverter](https://github.com/theislab/zellkonverter) (with the native R and the python reader)
and [anndataR](https://github.com/scverse/anndataR/) read in these H5AD files.

## Functionality testing
The `functionality_test` subdirectory contains the code used to determine what specific data types
are supported in each AnnData slot for each native R reader package.

This was done by generating datasets using [dummy-anndata](https://github.com/LouiseDck/dummy-anndata),
and compares performances of [schard](https://github.com/cellgeni/schard), [zellkonverter](https://github.com/theislab/zellkonverter) (with the native R reader) and [anndataR](https://github.com/scverse/anndataR/).

The results of this analysis can be found as Supplementary Table 1.
