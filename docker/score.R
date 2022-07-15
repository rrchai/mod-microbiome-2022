#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(yardstrick))

option_list <- list( 
    make_option(c('-p', '--predictions_file'),  type = "character"),
    make_option(c('-g', '--goldstandard_file'),  type = "character"),
    make_option(c('-o', '--output'),  type = "character", default="results.json"),
    make_option(c('-t', '--task'),  type = "character", default="1"),
    #make_option(c('-s', '--submission_number'), type = "integer")
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
result_list = list()
# result_list[['auc_roc']] <- roc_auc_vec(gold[[colname]], pred$probability)
# result_list[['auprc']] <- pr_auc_vec(gold[[colname]], pred$probability)
# result_list[['accuracy']] <- accuracy_vec(gold[[colname], pred[[colname]]])
# result_list[['sensitivity']] <- sens_vec(gold[[colname]], pred[[colname]])
# result_list[['specificity']] <- spec_vec(gold[[colname]], pred[[colname]])
# result_list[['mcc']] <- mcc_vec(gold[[colname]], pred[[colname]])

# Calculate bootstrapped scores, using a seed based on the current
# number of valid submissions + 1.
set.seed(args$submission_number + 1)
BS_n <- 1000
bs_indices <- matrix(1:nrow(gold), nrow(gold), N) %>%
    apply(2, sample, replace=T)

boot_auc_roc <- apply(bs_indices, 2, function(ind) {
    tmp <- pred[match(gold$participant, pred$participant), ]
    roc_auc_vec(gold[[colname]][ind], tmp$probability[ind])
}) %>% mean()
boot_aupr <- apply(bs_indices, 2, function(ind) {
    tmp <- pred[match(gold$participant, pred$participant), ]
    pr_auc_vec(gold[[colname]][ind], tmp$probability[ind])
}) %>% mean()
boot_acc <- apply(bs_indices, 2, function(ind) {
    tmp <- pred[match(gold$participant, pred$participant), ]
    accuracy_vec(gold[[colname]][ind], tmp$probability[ind])
}) %>% mean()
boot_sens <- apply(bs_indices, 2, function(ind) {
    tmp <- pred[match(gold$participant, pred$participant), ]
    sens_vec(gold[[colname]][ind], tmp$probability[ind])
}) %>% mean()
boot_spec <- apply(bs_indices, 2, function(ind) {
    tmp <- pred[match(gold$participant, pred$participant), ]
    spec_vec(gold[[colname]][ind], tmp$probability[ind])
}) %>% mean()

results_list[['boot_auc_roc']] <- boot_auc_roc
results_list[['boot_auprc']] <- boot_aupr
results_list[['boot_accuracy']] <- boot_acc
results_list[['boot_sensivity']] <- boot_sens
results_list[['boot_specificity']] <- boot_spec
result_list[['submission_status']] = "SCORED"

export_json <- toJSON(result_list, auto_unbox = TRUE, pretty=T)
write(export_json, args$results)
