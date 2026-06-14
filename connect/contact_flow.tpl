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
        "NextAction": "GetInput",
        "Errors": {},
        "Conditions": []
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
        "Errors": {
          "Timeout": "Disconnect",
          "Default": "Disconnect"
        },
        "Conditions": []
      }
    },
    {
      "Identifier": "CheckDTMF",
      "Type": "CheckContactAttributes",
      "Parameters": {},
      "Transitions": {
        "NextAction": "Disconnect",
        "Errors": {
          "Default": "Disconnect"
        },
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
        "NextAction": "InvokeLambdaAcknowledge",
        "Errors": {},
        "Conditions": []
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
        "Errors": {
          "Default": "SetContactAttributes"
        },
        "Conditions": []
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
        "NextAction": "PlayAcknowledgeConfirm",
        "Errors": {},
        "Conditions": []
      }
    },
    {
      "Identifier": "PlayAcknowledgeConfirm",
      "Type": "PlayPrompt",
      "Parameters": {
        "TextToSpeech": "Thank you. Your acknowledgement has been recorded. Goodbye."
      },
      "Transitions": {
        "NextAction": "Disconnect",
        "Errors": {},
        "Conditions": []
      }
    },
    {
      "Identifier": "Disconnect",
      "Type": "Disconnect",
      "Parameters": {},
      "Transitions": {}
    }
  ],
  "Metadata": {
    "Description": "Contact flow for incident alerts: plays prompt, collects DTMF, invokes Lambda for acknowledgement, or continues to IVR/agent routing."
  }
}
