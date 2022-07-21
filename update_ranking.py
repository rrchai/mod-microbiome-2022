"""Update Submission Ranks.

This script will rank submissions made to the Preterm Birth Prediction -
Microbiome Challenge (syn26133770) according to AUC-ROC and AUPRC.
"""
import os
import getpass

from challengeutils.annotations import update_submission_status
from challengeutils.utils import update_single_submission_status
import synapseclient

SUBMISSION_VIEWS = {
    "Task 1": "syn33100130",
    "Task 2": "syn33100594"
}


def login():
    """Log into Synapse. If env variables not found, prompt user."""
    try:
        syn = synapseclient.login(authToken=os.getenv('SYNAPSE_AUTH_TOKEN'),
                                  silent=True)
    except synapseclient.core.exceptions.SynapseNoCredentialsError:
        print("Credentials not found; please manually provide your",
              "Synapse username and password.")
        username = input("Synapse username: ")
        password = getpass.getpass("Synapse password: ")
        syn = synapseclient.login(username, password, silent=True)
    return syn


def rank_submissions(syn, subview_id):
    """
    Get scored submissions and rank them according to AUC-ROC, followed
    by AUPRC for tie-breakers.
    """
    query = (f"SELECT id, auc_roc, auprc FROM {subview_id} "
             f"WHERE submission_status = 'SCORED' "
             f"AND status = 'ACCEPTED'")
    submissions = syn.tableQuery(query).asDataFrame()
    submissions['rank'] = (
        submissions[['auc_roc', 'auprc']]
        .apply(tuple, axis=1)
        .rank(method='min', ascending=False)
        .astype(int)
    )
    return submissions


def annotate_submissions(syn, sub_df):
    """Annotate submissions with their new rank."""
    for _, row in sub_df.iterrows():
        annots = {'current_rank': int(row['rank'])}
        sub_status = syn.getSubmissionStatus(row['id'])
        updated = update_single_submission_status(
            sub_status, annots, is_private=False)
        updated = update_submission_status(updated, annots)
        syn.store(updated)


def main():
    """Main function."""
    syn = login()

    for task, syn_id in SUBMISSION_VIEWS.items():
        ranked_subs = rank_submissions(syn, syn_id)
        if not ranked_subs.empty:
            annotate_submissions(syn, ranked_subs)
        print(f"Annotating {task} submissions DONE ✓")


if __name__ == "__main__":
    main()
