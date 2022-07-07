#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow
label: UCSF Microbiome Challenge Evaluation
doc: |
  This workflow will run and evaluate a Docker submission to the MOD - Preterm
  Birth Prediction Microbiome Challenge (syn26133771). Metrics returned are ROC,
  PR, Accuracy, Sensitivity, Specificity.

requirements:
- class: StepInputExpressionRequirement

inputs:
  adminUploadSynId:
    label: Synapse Folder ID accessible by an admin
    type: string
  submissionId:
    label: Submission ID
    type: int
  submitterUploadSynId:
    label: Synapse Folder ID accessible by the submitter
    type: string
  synapseConfig:
    label: filepath to .synapseConfig file
    type: File
  workflowSynapseId:
    label: Synapse File ID that links to the workflow
    type: string

outputs: {}

steps:
  annotate_docker_upload_results:
    in:
    - id: submissionid
      source: '#submissionId'
    - id: annotation_values
      source: '#upload_results/results'
    - id: to_public
      default: true
    - id: force
      default: true
    - id: synapse_config
      source: '#synapseConfig'
    - id: previous_annotation_finished
      source: '#annotate_docker_validation_with_output/finished'
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.1/cwl/annotate_submission.cwl
    out:
    - finished
  annotate_docker_validation_with_output:
    in:
    - id: submissionid
      source: '#submissionId'
    - id: annotation_values
      source: '#validate_docker/results'
    - id: to_public
      default: true
    - id: force
      default: true
    - id: synapse_config
      source: '#synapseConfig'
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.1/cwl/annotate_submission.cwl
    out:
    - finished
  annotate_submission_with_output:
    in:
    - id: submissionid
      source: '#submissionId'
    - id: annotation_values
      source: '#score/results'
    - id: to_public
      default: true
    - id: force
      default: true
    - id: synapse_config
      source: '#synapseConfig'
    - id: previous_annotation_finished
      source: '#annotate_validation_with_output/finished'
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.1/cwl/annotate_submission.cwl
    out:
    - finished
  annotate_validation_with_output:
    in:
    - id: submissionid
      source: '#submissionId'
    - id: annotation_values
      source: '#validate/results'
    - id: to_public
      default: true
    - id: force
      default: true
    - id: synapse_config
      source: '#synapseConfig'
    - id: previous_annotation_finished
      source: '#annotate_docker_upload_results/finished'
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.1/cwl/annotate_submission.cwl
    out:
    - finished
  check_docker_status:
    in:
    - id: status
      source: '#validate_docker/status'
    - id: previous_annotation_finished
      source: '#annotate_docker_validation_with_output/finished'
    - id: previous_email_finished
      source: '#email_docker_validation/finished'
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.1/cwl/check_status.cwl
    out:
    - finished
  check_status:
    in:
    - id: status
      source: '#validate/status'
    - id: previous_annotation_finished
      source: '#annotate_validation_with_output/finished'
    - id: previous_email_finished
      source: '#email_validation/finished'
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.1/cwl/check_status.cwl
    out:
    - finished
  determine_question:
    in:
    - id: queue
      source: '#get_docker_submission/evaluation_id'
    run: steps/determine_question.cwl
    out:
    - id: task_number
  download_goldstandard:
    in:
    - id: synapseid
      valueFrom: syn32638781
    - id: synapse_config
      source: '#synapseConfig'
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks-Workflows/cwl-tool-synapseclient/v1.4/cwl/synapse-get-tool.cwl
    out:
    - id: filepath
  email_docker_validation:
    in:
    - id: submissionid
      source: '#submissionId'
    - id: synapse_config
      source: '#synapseConfig'
    - id: status
      source: '#validate_docker/status'
    - id: invalid_reasons
      source: '#validate_docker/invalid_reasons'
    - id: errors_only
      default: true
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.1/cwl/validate_email.cwl
    out:
    - finished
  email_score:
    in:
    - id: submissionid
      source: '#submissionId'
    - id: synapse_config
      source: '#synapseConfig'
    - id: results
      source: '#score/results'
    - id: private_annotations
      default:
      - mcc
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.1/cwl/score_email.cwl
    out: []
  email_validation:
    in:
    - id: submissionid
      source: '#submissionId'
    - id: synapse_config
      source: '#synapseConfig'
    - id: status
      source: '#validate/status'
    - id: invalid_reasons
      source: '#validate/invalid_reasons'
    - id: errors_only
      default: true
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.1/cwl/validate_email.cwl
    out:
    - finished
  get_docker_config:
    in:
    - id: synapse_config
      source: '#synapseConfig'
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.1/cwl/get_docker_config.cwl
    out:
    - id: docker_registry
    - id: docker_authentication
  get_docker_submission:
    in:
    - id: submissionid
      source: '#submissionId'
    - id: synapse_config
      source: '#synapseConfig'
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.1/cwl/get_submission.cwl
    out:
    - id: filepath
    - id: docker_repository
    - id: docker_digest
    - id: entity_id
    - id: entity_type
    - id: evaluation_id
    - id: results
  run_docker:
    in:
    - id: docker_repository
      source: '#get_docker_submission/docker_repository'
    - id: docker_digest
      source: '#get_docker_submission/docker_digest'
    - id: submissionid
      source: '#submissionId'
    - id: docker_registry
      source: '#get_docker_config/docker_registry'
    - id: docker_authentication
      source: '#get_docker_config/docker_authentication'
    - id: status
      source: '#validate_docker/status'
    - id: parentid
      source: '#submitterUploadSynId'
    - id: synapse_config
      source: '#synapseConfig'
    - id: store
      default: true
    - id: input_dir
      valueFrom: /home/ec2-user/training_data
    - id: name_prefix
      valueFrom: testing
    - id: docker_script
      default:
        class: File
        location: run_docker.py
    run: steps/run_docker.cwl
    out:
    - id: predictions
  score:
    in:
    - id: input_file
      source: '#run_docker/predictions'
    - id: goldstandard
      source: '#download_goldstandard/filepath'
    - id: task_number
      source: '#determine_question/task_number'
    - id: check_validation_finished
      source: '#check_status/finished'
    run: steps/score.cwl
    out:
    - id: results
  set_admin_folder_permissions:
    in:
    - id: entityid
      source: '#adminUploadSynId'
    - id: principalid
      valueFrom: '3433368'
    - id: permissions
      valueFrom: download
    - id: synapse_config
      source: '#synapseConfig'
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.1/cwl/set_permissions.cwl
    out: []
  set_submitter_folder_permissions:
    in:
    - id: entityid
      source: '#submitterUploadSynId'
    - id: principalid
      valueFrom: '3433368'
    - id: permissions
      valueFrom: download
    - id: synapse_config
      source: '#synapseConfig'
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.1/cwl/set_permissions.cwl
    out: []
  upload_results:
    in:
    - id: infile
      source: '#run_docker/predictions'
    - id: parentid
      source: '#adminUploadSynId'
    - id: used_entity
      source: '#get_docker_submission/entity_id'
    - id: executed_entity
      source: '#workflowSynapseId'
    - id: synapse_config
      source: '#synapseConfig'
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.1/cwl/upload_to_synapse.cwl
    out:
    - id: uploaded_fileid
    - id: uploaded_file_version
    - id: results
  validate:
    in:
    - id: input_file
      source: '#run_docker/predictions'
    - id: goldstandard
      source: '#download_goldstandard/filepath'
    - id: task_number
      source: '#determine_question/task_number'
    run: steps/validate.cwl
    out:
    - id: results
    - id: status
    - id: invalid_reasons
  validate_docker:
    in:
    - id: submissionid
      source: '#submissionId'
    - id: synapse_config
      source: '#synapseConfig'
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v3.1/cwl/validate_docker.cwl
    out:
    - id: results
    - id: status
    - id: invalid_reasons
