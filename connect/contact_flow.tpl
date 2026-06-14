{
  "Version": "2019-10-30",
  "StartAction": {
    "Identifier": "PlayIntro",
    "Type": "PlayPrompt",
    "Parameters": {}
  },
  "Actions": [
    {
      "Identifier": "PlayIntro",
      "Type": "PlayPrompt",
      "Parameters": {
        "TextToSpeech": "This is an automated incident alert from your monitoring system. Press 1 to acknowledge, 2 to request a call back, or stay on the line to speak to our automated assistant."
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
      }
    },
    {
      "Identifier": "CheckDTMF",
      "Type": "CheckContactAttributes",
      "Parameters": {}
    },
    {
      "Identifier": "RouteAcknowledge",
      "Type": "SetAttributes",
      "Parameters": {
        "Attributes": {
          "incident_action": "acknowledge"
        }
      }
    },
    {
      "Identifier": "InvokeLambdaAcknowledge",
      "Type": "InvokeAWSLambdaFunction",
      "Parameters": {
        "FunctionArn": "${lambda_arn}",
        "InvocationType": "Event"
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
      }
    },
    {
      "Identifier": "PlayAcknowledgeConfirm",
      "Type": "PlayPrompt",
      "Parameters": {
        "TextToSpeech": "Thank you. Your acknowledgement has been recorded. Goodbye."
      }
    },
    {
      "Identifier": "Disconnect",
      "Type": "Disconnect",
      "Parameters": {}
    }
  ],
  "Metadata": {
    "Description": "Contact flow for incident alerts: plays prompt, collects DTMF, invokes Lambda for acknowledgement, or continues to IVR/agent routing."
  }
}
