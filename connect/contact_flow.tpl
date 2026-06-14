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
      }
    },
    {
      "Identifier": "GetInput",
      "Type": "GetCustomerInput",
      "Parameters": {
        "TimeoutInSeconds": 8,
        "InputType": "DTMF",
        "MaxDigits": 1,
        "SpeechToText": false
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
            "Value": "1",
            "NextAction": "RouteAcknowledge"
          }
        ]
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
      }
    },
    {
      "Identifier": "Disconnect",
      "Type": "Disconnect",
      "Parameters": {}
    }
  ],
  "Metadata": {
    "Description": "Incident Contact Flow Architecture Block Map",
    "Type": "ContactFlow",
    "ActionMetadata": {
      "PlayIntro": { "XPosition": 100, "YPosition": 100 },
      "GetInput": { "XPosition": 300, "YPosition": 100 },
      "CheckDTMF": { "XPosition": 500, "YPosition": 100 },
      "RouteAcknowledge": { "XPosition": 700, "YPosition": 100 },
      "InvokeLambdaAcknowledge": { "XPosition": 900, "YPosition": 100 },
      "SetContactAttributes": { "XPosition": 1100, "YPosition": 100 },
      "PlayAcknowledgeConfirm": { "XPosition": 1300, "YPosition": 100 },
      "Disconnect": { "XPosition": 1500, "YPosition": 100 }
    }
  }
}
