{
  "Version": "2019-10-30",
  "StartAction": "PlayDynamicIntro",
  "Metadata": {
    "entryPointPosition": { "x": 20.0, "y": 20.0 },
    "ActionMetadata": {
      "PlayDynamicIntro": { "position": { "x": 150, "y": 50 } },
      "GetDeveloperInput": { "position": { "x": 400, "y": 50 } },
      "CheckPressedKey": { "position": { "x": 650, "y": 50 } },
      "LogAcknowledge": { "position": { "x": 900, "y": 50 } },
      "PlaySuccessGoodbye": { "position": { "x": 1150, "y": 50 } },
      "DisconnectSuccess": { "position": { "x": 1400, "y": 50 } },
      "PlayFailureMessage": { "position": { "x": 650, "y": 300 } },
      "TriggerEscalationLambda": { "position": { "x": 900, "y": 300 } },
      "DisconnectFailure": { "position": { "x": 1150, "y": 300 } }
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
      "Identifier": "PlayDynamicIntro",
      "Type": "MessageParticipant",
      "Transitions": {
        "NextAction": "GetDeveloperInput"
      }
    },
    {
      "Parameters": {
        "SkipWhenDTMFBufferEnabled": "false",
        "InputType": "DTMF",
        "MaxDigits": 1,
        "SpeechToText": false,
        "Text": "Would you like to acknowledge this incident? Press 1 to acknowledge, or hang up to escalate.",
        "CustomerInput": {}
      },
      "Identifier": "GetDeveloperInput",
      "Type": "GetCustomerInput",
      "Transitions": {
        "NextAction": "CheckPressedKey",
        "Errors": [
          {
            "NextAction": "PlayFailureMessage",
            "ErrorType": "NoMatch"
          },
          {
            "NextAction": "PlayFailureMessage",
            "ErrorType": "Timeout"
          }
        ]
      },
      "Metadata": {
        "position": { "x": 400, "y": 50 }
      }
    },
    {
      "Parameters": {
        "ComparisonAttributes": [
          {
            "Type": "System",
            "Attribute": "LastPressedDigit"
          }
        ]
      },
      "Transitions": {
        "NextAction": "PlayFailureMessage",
        "Errors": [
          { "ErrorType": "NoMatch", "NextAction": "PlayFailureMessage" }
        ],
        "Conditions": [
          {
            "MatchCriteria": { "Operator": "Equals", "Value": "1" },
            "NextAction": "LogAcknowledge"
          }
        ]
      },
      "Identifier": "CheckPressedKey",
      "Type": "CheckContactAttributes"
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
          { "NextAction": "PlaySuccessGoodbye", "ErrorType": "NoMatchingError" }
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
        "ResponseValidation": { "ResponseType": "STRING_MAP" }
      },
      "Identifier": "TriggerEscalationLambda",
      "Type": "InvokeLambdaFunction",
      "Transitions": {
        "NextAction": "DisconnectFailure",
        "Errors": [
          { "NextAction": "DisconnectFailure", "ErrorType": "NoMatchingError" }
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
f