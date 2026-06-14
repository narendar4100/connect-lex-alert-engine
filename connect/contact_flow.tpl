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
      "RouteAcknowledge": {
        "position": { "x": 400, "y": 50 }
      },
      "InvokeLambdaAcknowledge": {
        "position": { "x": 650, "y": 50 },
        "parameters": {
          "LambdaFunctionARN": {
            "displayName": "${lambda_arn}"
          }
        }
      },
      "SetContactAttributes": {
        "position": { "x": 900, "y": 50 }
      },
      "PlayAcknowledgeConfirm": {
        "position": { "x": 1150, "y": 50 }
      },
      "DisconnectNode": {
        "position": { "x": 1400, "y": 50 }
      }
    },
    "Annotations": [],
    "name": "Incident Management Flow",
    "description": "Parses incident notifications and logs automated responses natively.",
    "type": "contactFlow",
    "status": "PUBLISHED",
    "hash": {}
  },
  "Actions": [
    {
      "Parameters": {
        "SkipWhenDTMFBufferEnabled": "false",
        "Text": "This is an automated incident alert from your monitoring system. Please wait while we register your acknowledgement."
      },
      "Identifier": "PlayIntro",
      "Type": "MessageParticipant",
      "Transitions": {
        "NextAction": "RouteAcknowledge"
      }
    },
    {
      "Parameters": {
        "Attributes": {
          "incident_action": "acknowledge"
        },
        "TargetContact": "Current"
      },
      "Identifier": "RouteAcknowledge",
      "Type": "UpdateContactAttributes",
      "Transitions": {
        "NextAction": "InvokeLambdaAcknowledge",
        "Errors": [
          {
            "NextAction": "InvokeLambdaAcknowledge",
            "ErrorType": "NoMatchingError"
          }
        ]
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
      "Identifier": "InvokeLambdaAcknowledge",
      "Type": "InvokeLambdaFunction",
      "Transitions": {
        "NextAction": "SetContactAttributes",
        "Errors": [
          {
            "NextAction": "SetContactAttributes",
            "ErrorType": "NoMatchingError"
          }
        ]
      }
    },
    {
      "Parameters": {
        "Attributes": {
          "connect_instance_id": "${connect_instance_id}",
          "claim_phone_number": "${phone_number}"
        },
        "TargetContact": "Current"
      },
      "Identifier": "SetContactAttributes",
      "Type": "UpdateContactAttributes",
      "Transitions": {
        "NextAction": "PlayAcknowledgeConfirm",
        "Errors": [
          {
            "NextAction": "PlayAcknowledgeConfirm",
            "ErrorType": "NoMatchingError"
          }
        ]
      }
    },
    {
      "Parameters": {
        "SkipWhenDTMFBufferEnabled": "false",
        "Text": "Thank you. Your acknowledgement has been successfully recorded. Goodbye."
      },
      "Identifier": "PlayAcknowledgeConfirm",
      "Type": "MessageParticipant",
      "Transitions": {
        "NextAction": "DisconnectNode"
      }
    },
    {
      "Parameters": {},
      "Identifier": "DisconnectNode",
      "Type": "DisconnectParticipant",
      "Transitions": {}
    }
  ]
}
