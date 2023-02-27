resource "aws_sfn_state_machine" "emp_harvest_workflow" {
  name     = "emp-harvest-workflow"
  role_arn = aws_iam_role.emp_harvest_workflow_role.arn

  definition = <<EOF
{
  "Comment": "harvest an emp channel",
  "StartAt": "RetrieveHarvestConfiguration",
  "States": {
    "RetrieveHarvestConfiguration": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:ssm:getParameter",
      "Parameters": {
        "Name": "${aws_ssm_parameter.harvest_configuration.name}"
      },
      "ResultSelector": {
        "harvestConfiguration.$": "States.StringToJson($.Parameter.Value)"
      },
      "ResultPath": "$.stateOutput.harvestConfiguration",
      "Next": "IdentifyHarvestType"
    },
    "HarvestJobFail": {
      "Type": "Fail",
      "Cause": "Invalid response.",
      "Error": "ErrorA"
    },
    "IdentifyHarvestType": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.detail-type",
          "StringMatches": "Scheduled Event",
          "Next": "HourlyHarvestJobMap"
        },
        {
          "Variable": "$.detail-type",
          "StringMatches": "MediaLive Channel State Change",
          "Next": "ParseAdhocHarvestJobConfiguration"
        }
      ],
      "Default": "HarvestJobFail"
    },
    "HourlyHarvestJobMap": {
      "Type": "Map",
      "ItemsPath": "$.stateOutput.harvestConfiguration.harvestConfiguration.channelConfiguration",
      "ItemSelector": {
        "harvestJobType": "hourly",
        "time.$": "$.time",
        "bucketInformation.$": "$.stateOutput.harvestConfiguration.harvestConfiguration.bucketInformation",
        "channelConfiguration.$": "$.stateOutput.harvestConfiguration.harvestConfiguration.channelConfiguration",
        "channelInformation.$": "$$.Map.Item.Value"
      },
      "ItemProcessor": {
        "ProcessorConfig": {
          "Mode": "INLINE"
        },
        "StartAt": "PrepareHourlyHarvestJob",
        "States": {
          "PrepareHourlyHarvestJob": {
            "Type": "Task",
            "Resource": "arn:aws:states:::lambda:invoke",
            "Parameters": {
              "FunctionName": "${aws_lambda_function.prepare_harvest_job_function.function_name}",
              "Payload.$": "$"
            },
            "ResultPath": "$.stateOutput.harvestJobConfiguration",
            "Next": "CreateHourlyHarvestJob"
          },
          "CreateHourlyHarvestJob": {
            "Type": "Task",
            "Resource": "arn:aws:states:::aws-sdk:mediapackage:createHarvestJob",
            "Parameters": {
              "Id.$": "$.stateOutput.harvestJobConfiguration.Payload.harvestId",
              "OriginEndpointId.$": "$.stateOutput.harvestJobConfiguration.Payload.mediapackageOriginEndpointId",
              "StartTime.$": "$.stateOutput.harvestJobConfiguration.Payload.startTime",
              "EndTime.$": "$.stateOutput.harvestJobConfiguration.Payload.endTime",
              "S3Destination": {
                "BucketName.$": "$.stateOutput.harvestJobConfiguration.Payload.harvestBucket",
                "ManifestKey.$": "$.stateOutput.harvestJobConfiguration.Payload.harvestKey",
                "RoleArn": "${aws_iam_role.mediapackage_harvest_role.arn}"
              }
            },
            "End": true
          }
        }
      },
      "End": true
    },
    "ParseAdhocHarvestJobConfiguration": {
      "Type": "Pass",
      "Parameters": {
        "harvestJobType": "adhoc",
        "time.$": "$.time",
        "bucketInformation.$": "$.stateOutput.harvestConfiguration.harvestConfiguration.bucketInformation",
        "channelConfiguration.$": "$.stateOutput.harvestConfiguration.harvestConfiguration.channelConfiguration",
        "channelInformation.$": "$.detail"
      },
      "ResultPath": "$",
      "Next": "PrepareAdhocHarvestJob"
    },
    "PrepareAdhocHarvestJob": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "FunctionName": "${aws_lambda_function.prepare_harvest_job_function.function_name}",
        "Payload.$": "$"
      },
      "ResultPath": "$.stateOutput.harvestJobConfiguration",
      "Next": "FilterChannel"
    },
    "FilterChannel": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.stateOutput.harvestJobConfiguration.Payload.filterException",
          "IsPresent": true,
          "Next": "FilteredOutChannel"
        }
      ],
      "Default": "CreateAdhocHarvestJob"
    },
    "FilteredOutChannel": {
      "Type": "Succeed"
    },
    "CreateAdhocHarvestJob": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:mediapackage:createHarvestJob",
      "Parameters": {
        "Id.$": "$.stateOutput.harvestJobConfiguration.Payload.harvestId",
        "OriginEndpointId.$": "$.stateOutput.harvestJobConfiguration.Payload.mediapackageOriginEndpointId",
        "StartTime.$": "$.stateOutput.harvestJobConfiguration.Payload.startTime",
        "EndTime.$": "$.stateOutput.harvestJobConfiguration.Payload.endTime",
        "S3Destination": {
          "BucketName.$": "$.stateOutput.harvestJobConfiguration.Payload.harvestBucket",
          "ManifestKey.$": "$.stateOutput.harvestJobConfiguration.Payload.harvestKey",
          "RoleArn": "${aws_iam_role.mediapackage_harvest_role.arn}"
        }
      },
      "End": true
    }
  }
}
EOF
}
