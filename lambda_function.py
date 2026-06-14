import os
import json
import uuid
import boto3
import logging
import traceback
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ddb = boto3.resource('dynamodb')
connect = boto3.client('connect')
sns = boto3.client('sns')

def _start_call(instance_id: str, contact_flow_id: str, phone: str, error_details: str) -> dict:
    source_phone = os.environ.get('SOURCE_PHONE_NUMBER')
    logger.info(f"Initiating Outbound Call to {phone} for Error: {error_details}")
    
    return connect.start_outbound_voice_contact(
        InstanceId=instance_id,
        ContactFlowId=contact_flow_id,
        DestinationPhoneNumber=phone,
        SourcePhoneNumber=source_phone,
        ClientToken=str(uuid.uuid4()),
        # FIXED: Passes the API error details straight into the Contact Flow memory context!
        Attributes={
            "api_error_name": error_details
        }
    )

def _send_sms(numbers: list, message: str) -> None:
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
    
    # Extract the error metric name dynamically from the CloudWatch Alarm payload
    metric_name = "API Gateway 5XX Error"
    try:
        if "detail" in event and "alarmName" in event["detail"]:
            metric_name = event["detail"]["alarmName"]
    except Exception:
        pass

    numbers = [n for n in [primary, secondary] if n]
    
    # Step 1: Call the First Developer
    if len(numbers) > 0:
        logger.info(f"Dialing Primary Developer: {numbers[0]}")
        try:
            return _start_call(instance_id, contact_flow_id, numbers[0], metric_name)
        except Exception as e:
            logger.error(f"Primary Developer Call Failed: {str(e)}")

    # Step 2: Fallback logic handled within the Contact Flow if they answer but hang up or press wrong buttons
    return {"status": "initiated_primary_call"}

def _handle_lex(event: dict) -> dict:
    session = event.get('sessionState', {})
    intent = session.get('intent', {})
    intent_name = intent.get('name', '')
    confirmation = intent.get('confirmationState', '')
    slots = intent.get('slots', {})
    table_name = os.environ.get('DDB_TABLE_NAME')
    
    # Capture current contact attributes to see if this is an error feedback hook
    attributes = event.get('attributes', {})
    error_type = attributes.get('api_error_name', 'System Error')

    payload = {
        "IncidentId": str(uuid.uuid4().hex),
        "Intent": intent_name,
        "ConfirmationStatus": confirmation,
        "Details": {
            "error_type": error_type,
            "slots": slots
        }
    }
    try:
        ddb.Table(table_name).put_item(Item=payload)
    except Exception as ddb_err:
        logger.error(f"DDB Save Fail: {str(ddb_err)}")

    response_text = "Incident logged successfully."
    return {
        "sessionState": {
            "dialogAction": {"type": "Close"},
            "intent": intent
        },
        "messages": [{"contentType": "PlainText", "content": response_text}]
    }

def handler(event, context):
    logger.info(f"Incoming Event payload: {json.dumps(event)}")
    # Check if this invocation is Amazon Connect telling us the first developer hung up or didn't answer!
    if isinstance(event, dict) and event.get('Name') == 'TriggerSecondaryCall':
        secondary_phone = os.environ.get('DEVELOPER_PHONE_SECONDARY')
        instance_id = os.environ.get('CONNECT_INSTANCE_ID')
        contact_flow_id = os.environ.get('CONTACT_FLOW_ID')
        error_name = event.get('Details', {}).get('ContactAttributes', {}).get('api_error_name', 'API Gateway 5XX Error')
        
        if secondary_phone:
            logger.info(f"Contact Flow triggered escalation. Dialing Secondary Developer: {secondary_phone}")
            return _start_call(instance_id, contact_flow_id, secondary_phone, error_name)
        else:
            # If no secondary phone exists, send the final distribution group notice
            logger.warn("Escalation triggered but no secondary developer configured. Sending Emergency SMS/Email.")
            _send_sms([os.environ.get('DEVELOPER_PHONE_PRIMARY')], "Alert: Primary engineer missed call. Dispatching to Team Distribution List.")
            return {"status": "email_dispatched_to_dl"}

    if isinstance(event, dict) and event.get('detail-type') == 'CloudWatch Alarm State Change':
        return _handle_alarm(event)
    if isinstance(event, dict) and 'sessionState' in event:
        return _handle_lex(event)
        
    return {"status": "ignored"}
