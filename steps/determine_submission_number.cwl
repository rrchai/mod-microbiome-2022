#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: Get current submission number

requirements:
- class: InlineJavascriptRequirement
- class: InitialWorkDirRequirement
  listing:
  - entryname: get_submission_number.py
    entry: |
      #!/usr/bin/env python
      import argparse

      import synapseclient

      parser = argparse.ArgumentParser()
      parser.add_argument("-s", "--submission_id", required=True, help="Submission ID")
      parser.add_argument("-e", "--evaluation_id", required=True, help="Evaluation ID")
      parser.add_argument("-v", "--submission_view", required=True, help="Submission View")
      parser.add_argument("-c", "--config", required=True, help="Config file with Synapese credentials")

      args = parser.parse_args()
      syn = synapseclient.Synapse(configPath=args.config)
      syn.login(silent=True)

      submission = syn.getSubmission(args.submission_id, downloadFile=False)
      submitter = submission.get("teamId", submission["userId"])

      query = (f"SELECT count(*) FROM {args.submission_view} "
               f"WHERE evaluationid = {args.evaluation_id} "
               f"AND submitterid = {submitter} AND status = 'ACCEPTED'")
      submissions_count = len(syn.tableQuery(query, resultsAs="rowset"))

      with open("output.txt", "w") as o:
        o.write(str(submissions_count))

inputs:
- id: submission_id
  type: int
  inputBinding:
    prefix: -s
- id: queue
  type: string
  inputBinding:
    prefix: -e
- id: submission_view
  type: string
  inputBinding:
    prefix: -v
- id: synapse_config
  type: File
  inputBinding:
    prefix: -c

outputs:
  submission_number:
    type: int
    outputBinding:
      glob: output.txt
      outputEval: $(parseInt(self[0].contents))
      loadContents: true

baseCommand:
- python3
- get_submission_number.py

hints:
  DockerRequirement:
    dockerPull: sagebionetworks/synapsepythonclient:v2.6.0
