import os
import json
import uuid
import boto3
from datetime import datetime

ddb = boto3.resource('dynamodb')
connect = boto3.client('connect')
sns = boto3.client('sns')

def _start_call(instance_id: str, contact_flow_id: str, phone: str) -> dict:
    return connect.start_outbound_voice_contact(
        InstanceId=instance_id,
        ContactFlowId=contact_flow_id,
        DestinationPhoneNumber=phone,
        ClientToken=str(uuid.uuid4())
    )

def _write_ddb(table_name: str, payload: dict) -> None:
    table = ddb.Table(table_name)
    item = {
        "IncidentId": payload.get("IncidentId", uuid.uuid4().hex),
        "Timestamp": datetime.utcnow().isoformat(),
        "Intent": payload.get("Intent", ""),
        "ConfirmationStatus": payload.get("ConfirmationStatus", ""),
        "Details": json.dumps(payload.get("Details", {}))
    }
    table.put_item(Item=item)

def _send_sms(numbers: list[str], message: str) -> None:
    for num in numbers:
        try:
            sns.publish(PhoneNumber=num, Message=message)
        except Exception:
            pass

def _handle_alarm(event: dict) -> dict:
    primary = os.environ.get('DEVELOPER_PHONE_PRIMARY')
    secondary = os.environ.get('DEVELOPER_PHONE_SECONDARY')
    instance_id = os.environ.get('CONNECT_INSTANCE_ID')
    contact_flow_id = os.environ.get('CONTACT_FLOW_ID')
    numbers = [n for n in [primary, secondary] if n]
    attempts = 3
    for i in range(attempts):
        target = numbers[i % len(numbers)]
        try:
            resp = _start_call(instance_id, contact_flow_id, target)
            return resp
        except Exception:
            continue
    _send_sms(numbers, "Alert: Unable to reach on-call developers. Please investigate.")
    return {"status": "failed_to_contact"}

def _handle_lex(event: dict) -> dict:
    session = event.get('sessionState', {})
    intent = session.get('intent', {})
    intent_name = intent.get('name', '')
    confirmation = intent.get('confirmationState', '')
    slots = intent.get('slots', {})
    table_name = os.environ.get('DDB_TABLE_NAME')
    dev_primary = os.environ.get('DEVELOPER_PHONE_PRIMARY')
    dev_secondary = os.environ.get('DEVELOPER_PHONE_SECONDARY')
    payload = {
        "IncidentId": str(uuid.uuid4().hex),
        "Intent": intent_name,
        "ConfirmationStatus": confirmation,
        "Details": {
            "sessionId": event.get('sessionId'),
            "userId": event.get('userId'),
            "slots": slots
        }
    }
    _write_ddb(table_name, payload)
    if intent_name == "AcknowledgeIncidentIntent":
        response_text = "Incident acknowledged. We'll follow up."
    elif intent_name == "ClosingIntent":
        response_text = "Closing the incident. Thank you."
    else:
        response_text = "I have logged the incident."
    response = {
        "sessionState": {
            "dialogAction": {"type": "Close"},
            "intent": intent
        },
        "messages": [
            {"contentType": "PlainText", "content": response_text}
        ]
    }
    return response

def handler(event, context):
    if isinstance(event, dict) and event.get('detail-type') == 'CloudWatch Alarm State Change':
        return _handle_alarm(event)
    if isinstance(event, dict) and 'sessionState' in event:
        return _handle_lex(event)
    return {"status": "ignored"}
