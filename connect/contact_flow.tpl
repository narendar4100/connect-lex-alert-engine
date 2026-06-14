{
  "Version": "2019-10-30",
  "StartAction": "PlayIntro",
  "Actions": [
    {
      "Identifier": "PlayIntro",
      "Type": "PlayPrompt",
      "Parameters": {
        "TextToSpeech": "This is an automated incident alert from your monitoring system. Press 1 to acknowledge, 2 to request a call back, or stay on the line to speak to our automated assistant."
      },
      "Transitions": {
        "NextAction": "GetInput"
      },
      "Metadata": {
        "position": { "x": 100, "y": 100 }
      }
    },
    {
      "Identifier": "GetInput",
      "Type": "GetCustomerInput",
      "Parameters": {
        "TimeoutInSeconds": 8,
        "InputType": "DTMF",
        "MaxDigits": 1,
        "SpeechToText": false,
        "CustomerInput": {}
      },
      "Transitions": {
        "NextAction": "CheckDTMF",
        "Errors": [
          {
            "ErrorType": "NoMatch",
            "NextAction": "Disconnect"
          },
          {
            "ErrorType": "Timeout",
            "NextAction": "Disconnect"
          }
        ]
      },
      "Metadata": {
        "position": { "x": 300, "y": 100 }
      }
    },
    {
      "Identifier": "CheckDTMF",
      "Type": "CheckContactAttributes",
      "Parameters": {
        "ComparisonAttributes": [
          {
            "Type": "System",
            "Attribute": "LastPressedDigit"
          }
        ]
      },
      "Transitions": {
        "NextAction": "Disconnect",
        "Conditions": [
          {
            "ConditionType": "Equals",
            "Value": "1",
            "NextAction": "RouteAcknowledge"
          }
        ]
      },
      "Metadata": {
        "position": { "x": 500, "y": 100 }
      }
    },
    {
      "Identifier": "RouteAcknowledge",
      "Type": "SetAttributes",
      "Parameters": {
        "Attributes": {
          "incident_action": "acknowledge"
        }
      },
      "Transitions": {
        "NextAction": "InvokeLambdaAcknowledge"
      },
      "Metadata": {
        "position": { "x": 700, "y": 100 }
      }
    },
    {
      "Identifier": "InvokeLambdaAcknowledge",
      "Type": "InvokeAWSLambdaFunction",
      "Parameters": {
        "FunctionArn": "${lambda_arn}",
        "InvocationType": "Event"
      },
      "Transitions": {
        "NextAction": "SetContactAttributes",
        "Errors": [
          {
            "ErrorType": "Default",
            "NextAction": "SetContactAttributes"
          }
        ]
      },
      "Metadata": {
        "position": { "x": 900, "y": 100 }
      }
    },
    {
      "Identifier": "SetContactAttributes",
      "Type": "SetAttributes",
      "Parameters": {
        "Attributes": {
          "connect_instance_id": "${connect_instance_id}",
          "claim_phone_number": "${phone_number}"
        }
      },
      "Transitions": {
        "NextAction": "PlayAcknowledgeConfirm"
      },
      "Metadata": {
        "position": { "x": 1100, "y": 100 }
      }
    },
    {
      "Identifier": "PlayAcknowledgeConfirm",
      "Type": "PlayPrompt",
      "Parameters": {
        "TextToSpeech": "Thank you. Your acknowledgement has been recorded. Goodbye."
      },
      "Transitions": {
        "NextAction": "Disconnect"
      },
      "Metadata": {
        "position": { "x": 1300, "y": 100 }
      }
    },
    {
      "Identifier": "Disconnect",
      "Type": "Disconnect",
      "Parameters": {},
      "Metadata": {
        "position": { "x": 1500, "y": 100 }
      }
    }
  ],
  "Metadata": {
    "Description": "Incident Contact Flow Architecture Block Map",
    "Type": "ContactFlow"
  }
}
