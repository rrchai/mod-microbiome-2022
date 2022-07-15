#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(magrittr))
suppressPackageStartupMessages(library(yardstick))

option_list <- list( 
    make_option(c('-p', '--predictions_file'),  type = "character"),
    make_option(c('-g', '--goldstandard_file'),  type = "character"),
    make_option(c('-o', '--output'),  type = "character", default="results.json"),
    make_option(c('-t', '--task'),  type = "character", default="1"),
    make_option(c('-s', '--submission_number'), type = "integer")
)
args <- parse_args(OptionParser(option_list=option_list))

# Read in files and ensure participant order matches between the files.
gold <- read_csv(args$goldstandard_file, col_types=cols("c", "f", "d"))
pred <- read_csv(args$predictions_file, col_types=cols("c", "f"))
pred <- pred[match(gold$participant, pred$participant), ]

# Set colname depending on task number.
colname <- ifelse(args$task == "1", "was_preterm", "was_early_preterm")

# Set factor levels (otherwise, they will be mismatched).
gold[[colname]] <- factor(gold[[colname]], levels=c(1,0))
pred[[colname]] <- factor(pred[[colname]], levels=c(1,0))

# Calculate the true scores first.
true_scores <- list(
    "auc_roc" = roc_auc_vec(gold[[colname]], pred$probability),
    "auprc" = pr_auc_vec(gold[[colname]], pred$probability),
    "accuracy" = accuracy_vec(gold[[colname]], pred[[colname]]),
    "sensitivity" = sens_vec(gold[[colname]], pred[[colname]]),
    "specificity" = spec_vec(gold[[colname]], pred[[colname]]),
    "mcc" = mcc_vec(gold[[colname]], pred[[colname]])
)
export_json <- toJSON(true_scores, auto_unbox = TRUE, pretty=T)
write(export_json, "true_results.json")

# Calculate bootstrapped scores, using a seed based on the current
# number of valid submissions + 1.
set.seed(args$submission_number + 1)
BS_n <- 100
bs_indices <- matrix(1:nrow(gold), nrow(gold), BS_n) %>%
    apply(2, sample, replace=T)

boot_auc_roc <- apply(bs_indices[1:37,], 2, function(ind) {
    tmp <- pred[match(gold$participant, pred$participant), ]
    roc_auc_vec(gold[[colname]][ind], tmp$probability[ind])
}) %>% median()
boot_aupr <- apply(bs_indices[1:37,], 2, function(ind) {
    tmp <- pred[match(gold$participant, pred$participant), ]
    pr_auc_vec(gold[[colname]][ind], tmp$probability[ind])
}) %>% median()
boot_acc <- apply(bs_indices[1:37,], 2, function(ind) {
    tmp <- pred[match(gold$participant, pred$participant), ]
    accuracy_vec(gold[[colname]][ind], tmp[[colname]][ind])
}) %>% median()
boot_sens <- apply(bs_indices[1:37,], 2, function(ind) {
    tmp <- pred[match(gold$participant, pred$participant), ]
    sens_vec(gold[[colname]][ind], tmp[[colname]][ind])
}) %>% median()
boot_spec <- apply(bs_indices[1:37,], 2, function(ind) {
    tmp <- pred[match(gold$participant, pred$participant), ]
    spec_vec(gold[[colname]][ind], tmp[[colname]][ind])
}) %>% median()

bs_scores <- list(
    "boot_auc_roc" = boot_auc_roc,
    "boot_auprc" = boot_aupr,
    "boot_accuracy" = boot_acc,
    "boot_sensitivity" = boot_sens,
    "boot_specificity" = boot_spec,
    "submission_status" = "SCORED"
)
export_json <- toJSON(bs_scores, auto_unbox = TRUE, pretty=T)
write(export_json, args$output)

