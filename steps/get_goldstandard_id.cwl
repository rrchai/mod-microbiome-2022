#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: ExpressionTool
label: Get Synase ID to goldstandard file based on task

requirements:
- class: InlineJavascriptRequirement

inputs:
- id: task_number
  type: string

outputs:
- id: id
  type: string

expression: |

  ${
    if(inputs.task_number == "1") {
      return {id: "syn32638781"};
    } else {
      return {id: "syn32638782"};
    }
  }