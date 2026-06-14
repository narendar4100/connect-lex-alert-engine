{
  "Version": "2019-10-30",
  "StartAction": "PlayIntro",
  "Metadata": {
    "entryPointPosition": {
      "x": 20.0,
      "y": 20.0
    },
    "ActionMetadata": {
      "PlayIntro": {
        "position": { "x": 150, "y": 50 }
      },
      "GetDeveloperInput": {
        "position": { "x": 400, "y": 50 }
      },
      "CheckPressedKey": {
        "position": { "x": 650, "y": 50 },
        "conditions": [],
        "conditionMetadata": [
          {
            "id": "match-digit-1",
            "operator": {
              "name": "Equals",
              "value": "Equals",
              "shortDisplay": "="
            },
            "value": "1"
          }
        ]
      },
      "LogAcknowledge": {
        "position": { "x": 900, "y": 50 }
      },
      "PlaySuccessGoodbye": {
        "position": { "x": 1150, "y": 50 }
      },
      "PlayFailureMessage": {
        "position": { "x": 400, "y": 300 }
      },
      "TriggerEscalationLambda": {
        "position": { "x": 650, "y": 300 }
      },
      "DisconnectSuccess": {
        "position": { "x": 1400, "y": 50 }
      },
      "DisconnectFailure": {
        "position": { "x": 900, "y": 300 }
      }
    },
    "Annotations": [],
    "name": "Incident Management Flow",
    "description": "Natively parses incident tracking alerts, implements on-call secondary cascading escalation structures.",
    "type": "contactFlow",
    "status": "PUBLISHED",
    "hash": {}
  },
  "Actions": [
    {
      "Parameters": {
        "SkipWhenDTMFBufferEnabled": "false",
        "Text": "This is an automated incident alert. We have detected a system issue related to $.Attributes.api_error_name."
      },
      "Identifier": "PlayIntro",
      "Type": "MessageParticipant",
      "Transitions": {
        "NextAction": "GetDeveloperInput"
      }
    },
    {
      "Parameters": {
        "SkipWhenDTMFBufferEnabled": "false",
        "Text": "Would you like to acknowledge this incident? Press 1 to acknowledge, or hang up to escalate."
      },
      "Identifier": "GetDeveloperInput",
      "Type": "MessageParticipant",
      "Transitions": {
        "NextAction": "CheckPressedKey"
      }
    },
    {
      "Parameters": {
        "ComparisonValue": "$.LastPressedDigit"
      },
      "Identifier": "CheckPressedKey",
      "Type": "Compare",
      "Transitions": {
        "NextAction": "PlayFailureMessage",
        "Conditions": [
          {
            "NextAction": "LogAcknowledge",
            "Condition": {
              "Operator": "Equals",
              "Operands": [
                "1"
              ]
            }
          }
        ],
        "Errors": [
          {
            "NextAction": "PlayFailureMessage",
            "ErrorType": "NoMatchingCondition"
          }
        ]
      }
    },
    {
      "Parameters": {
        "Attributes": {
          "incident_action": "developer_acknowledged"
        },
        "TargetContact": "Current"
      },
      "Identifier": "LogAcknowledge",
      "Type": "UpdateContactAttributes",
      "Transitions": {
        "NextAction": "PlaySuccessGoodbye",
        "Errors": [
          {
            "NextAction": "PlaySuccessGoodbye",
            "ErrorType": "NoMatchingError"
          }
        ]
      }
    },
    {
      "Parameters": {
        "SkipWhenDTMFBufferEnabled": "false",
        "Text": "Thank you. Your acknowledgement has been successfully recorded. Investigating engineers have been notified. Goodbye."
      },
      "Identifier": "PlaySuccessGoodbye",
      "Type": "MessageParticipant",
      "Transitions": {
        "NextAction": "DisconnectSuccess"
      }
    },
    {
      "Parameters": {
        "SkipWhenDTMFBufferEnabled": "false",
        "Text": "I did not receive a correct confirmation response. I am now cascading this alert to the secondary on-call engineer or email distribution lists. Please stand by."
      },
      "Identifier": "PlayFailureMessage",
      "Type": "MessageParticipant",
      "Transitions": {
        "NextAction": "TriggerEscalationLambda"
      }
    },
    {
      "Parameters": {
        "LambdaFunctionARN": "${lambda_arn}",
        "InvocationTimeLimitSeconds": "4",
        "InvocationType": "SYNCHRONOUS",
        "ResponseValidation": {
          "ResponseType": "STRING_MAP"
        }
      },
      "Identifier": "TriggerEscalationLambda",
      "Type": "InvokeLambdaFunction",
      "Transitions": {
        "NextAction": "DisconnectFailure",
        "Errors": [
          {
            "NextAction": "DisconnectFailure",
            "ErrorType": "NoMatchingError"
          }
        ]
      }
    },
    {
      "Parameters": {},
      "Identifier": "DisconnectSuccess",
      "Type": "DisconnectParticipant",
      "Transitions": {}
    },
    {
      "Parameters": {},
      "Identifier": "DisconnectFailure",
      "Type": "DisconnectParticipant",
      "Transitions": {}
    }
  ]
}
