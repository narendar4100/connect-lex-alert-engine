import os
import json
import uuid
import boto3
from datetime import datetime

ddb = boto3.resource('dynamodb')
connect = boto3.client('connect')

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

def _handle_alarm(event: dict) -> dict:
    primary = os.environ.get('DEVELOPER_PHONE_PRIMARY')
    secondary = os.environ.get('DEVELOPER_PHONE_SECONDARY')
    instance_id = os.environ.get('CONNECT_INSTANCE_ID')
    contact_flow_id = os.environ.get('CONTACT_FLOW_ID')
    try:
        return _start_call(instance_id, contact_flow_id, primary)
    except Exception:
        return _start_call(instance_id, contact_flow_id, secondary)

def _handle_lex(event: dict) -> dict:
    session = event.get('sessionState', {})
    intent = session.get('intent', {})
    intent_name = intent.get('name', '')
    confirmation = intent.get('confirmationState', '')
    table_name = os.environ.get('DDB_TABLE_NAME')
    payload = {
        "IncidentId": str(uuid.uuid4().hex),
        "Intent": intent_name,
        "ConfirmationStatus": confirmation,
        "Details": {
            "sessionId": event.get('sessionId'),
            "userId": event.get('userId')
        }
    }
    _write_ddb(table_name, payload)
    response = {
        "sessionState": {
            "dialogAction": {"type": "Close"},
            "intent": intent
        },
        "messages": [
            {"contentType": "PlainText", "content": "Incident logged"}
        ]
    }
    return response

def handler(event, context):
    if isinstance(event, dict) and event.get('detail-type') == 'CloudWatch Alarm State Change':
        return _handle_alarm(event)
    if isinstance(event, dict) and 'sessionState' in event:
        return _handle_lex(event)
    return {"status": "ignored"}
import os
import json
import uuid
import boto3
from datetime import datetime

ddb = boto3.resource('dynamodb')
connect = boto3.client('connect')

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

def _handle_alarm(event: dict) -> dict:
    primary = os.environ.get('DEVELOPER_PHONE_PRIMARY')
    secondary = os.environ.get('DEVELOPER_PHONE_SECONDARY')
    instance_id = os.environ.get('CONNECT_INSTANCE_ID')
    contact_flow_id = os.environ.get('CONTACT_FLOW_ID')
    try:
        return _start_call(instance_id, contact_flow_id, primary)
    except Exception:
        return _start_call(instance_id, contact_flow_id, secondary)

def _handle_lex(event: dict) -> dict:
    session = event.get('sessionState', {})
    intent = session.get('intent', {})
    intent_name = intent.get('name', '')
    confirmation = intent.get('confirmationState', '')
    table_name = os.environ.get('DDB_TABLE_NAME')
    payload = {
        "IncidentId": str(uuid.uuid4().hex),
        "Intent": intent_name,
        "ConfirmationStatus": confirmation,
        "Details": {
            "sessionId": event.get('sessionId'),
            "userId": event.get('userId')
        }
    }
    _write_ddb(table_name, payload)
    response = {
        "sessionState": {
            "dialogAction": {"type": "Close"},
            "intent": intent
        },
        "messages": [
            {"contentType": "PlainText", "content": "Incident logged"}
        ]
    }
    return response

def handler(event, context):
    if isinstance(event, dict) and event.get('detail-type') == 'CloudWatch Alarm State Change':
        return _handle_alarm(event)
    if isinstance(event, dict) and 'sessionState' in event:
        return _handle_lex(event)
    return {"status": "ignored"}
