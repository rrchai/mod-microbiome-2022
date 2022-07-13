#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(jsonlite))

option_list <- list( 
    make_option(c('-p', '--predictions_file'),  type = "character"),
    make_option(c('-g', '--goldstandard_file'),  type = "character"),
    make_option(c('-o', '--output'),  type = "character"),
    make_option(c('-t', '--task'),  type = "character"),
    make_option(c('-s', '--submission_number'), type = "integer")
)
args <- parse_args(OptionParser(option_list=option_list))

pred <- read.csv(args$predictions_file)
gold <- read.csv(args$goldstandard_file)

# Match the row order of predictions to goldstandard file
pred <- pred[match(gold$participant, pred$participant), ]

# Return bootstrapped scores (to help prevent overfitting)
## Set the seed for the bootstrap sampling. Seed number will be
## dependent on which submission number the submitter is on.
valid_subs <- args$submission_number
SEED <- valid_subs + 1
BS_n <- 10

scores <- master_BS_wrapper(gold, pred, N=BS_n, seed = SEED)

roc  <- scores$roc
pr   <- scores$pr
acc  <- scores$accuracy
sens <- scores$sensitivity
spec <- scores$specificity
mcc  <- scores$matthewscoeff

result_list = list()
result_list[['auc_roc']] = roc
result_list[['auprc']] = pr
result_list[['accuracy']] = acc
result_list[['sensitivity']] = sens
result_list[['specificity']] = spec
result_list[['mcc']] = mcc

result_list[['submission_status']] = "SCORED"

export_json <- toJSON(result_list, auto_unbox = TRUE, pretty=T)
write(export_json, args$results)