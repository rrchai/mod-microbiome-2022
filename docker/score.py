#!/usr/bin/env python3
"""Score prediction file.

Task 1 and 2 will return the same metrics:
    - ROC curve
    - PR curve
    - accuracy
    - sensitivity
    - specificity
"""

import argparse
import json

import pandas as pd
from sklearn.metrics import (roc_auc_score,
                             average_precision_score,
                             confusion_matrix,
                             matthews_corrcoef)

COLNAME = {
    "1": 'was_preterm',
    "2": 'was_early_preterm'
}


def get_args():
    """Set up command-line interface and get arguments."""
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--predictions_file",
                        type=str, required=True)
    parser.add_argument("-g", "--goldstandard_file",
                        type=str, required=True)
    parser.add_argument("-t", "--task", type=str, default="1")
    parser.add_argument("-o", "--output", type=str, default="results.json")
    return parser.parse_args()


def score(gold, pred, col):
    """
    Calculate metrics for: AUC-ROC, AUCPR, accuracy,
    sensitivity, specificity, and MCC (for funsies).
    """
    roc = roc_auc_score(gold[col], pred[col])
    pr = average_precision_score(gold[col], pred[col])
    mat = confusion_matrix(gold[col], pred[col])
    acc = (mat[0, 0] + mat[1, 1]) / sum(sum(mat))
    sens = mat[0, 0] / (mat[0, 0] + mat[0, 1])
    spec = mat[1, 1] / (mat[1, 0] + mat[1, 1])
    mcc = matthews_corrcoef(gold[col], pred[col])

    return {
        'auc_roc': roc, 'auprc': pr,
        'accuracy': acc, 'sensitivity': sens,
        'specificity': spec, 'mcc': mcc
    }


def main():
    """Main function."""
    args = get_args()

    pred = pd.read_csv(args.predictions_file)
    gold = pd.read_csv(args.goldstandard_file)
    scores = score(gold, pred, COLNAME[args.task])

    with open(args.output, "w") as out:
        res = {
            "submission_status": "SCORED",
            **scores
        }
        out.write(json.dumps(res))


if __name__ == "__main__":
    main()
