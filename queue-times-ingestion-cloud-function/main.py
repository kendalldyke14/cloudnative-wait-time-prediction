import requests
import pathlib as path
import json
from os import path, environ
import time
from google.cloud import storage
import base64
import google.cloud.logging
import logging

def pub_sub_trigger(event, context):
    """Background Cloud Function to be triggered by Pub/Sub.
    Args:
         event (dict):  The dictionary with data specific to this type of
                        event. The `@type` field maps to
                         `type.googleapis.com/google.pubsub.v1.PubsubMessage`.
                        The `data` field maps to the PubsubMessage data
                        in a base64-encoded string. The `attributes` field maps
                        to the PubsubMessage attributes if any is present.
         context (google.cloud.functions.Context): Metadata of triggering event
                        including `event_id` which maps to the PubsubMessage
                        messageId, `timestamp` which maps to the PubsubMessage
                        publishTime, `event_type` which maps to
                        `google.pubsub.topic.publish`, and `resource` which is
                        a dictionary that describes the service API endpoint
                        pubsub.googleapis.com, the triggering topic's name, and
                        the triggering event type
                        `type.googleapis.com/google.pubsub.v1.PubsubMessage`.
    Returns:
        None. A file is written to Google Cloud Storage.
    """

    print(
        """This Function was triggered by messageId {} published at {} to {} with message {}
    """.format(
            context.event_id, context.timestamp, context.resource["name"], event["data"]
        )
    )
    if "data" in event:
        park_list = json.loads(base64.b64decode(event["data"]).decode("utf-8"))
        for d in park_list["parks"]:
            get_queue_times_api_to_gcs(d["theme_park_id"], d["park_name"], d["readable_park_name"])
    else:
        get_queue_times_api_to_gcs(6, "magickingdom", "Magic Kingdom")


def get_queue_times_api_to_gcs(theme_park_id:int, theme_park_name:str, readable_park_name:str):
    project_id, now, queue_times_url = setup(theme_park_id)
    json_data = call_queue_times_api(queue_times_url)
    blob = create_json_file(theme_park_id, theme_park_name, project_id, now, json_data, readable_park_name)
    
    write_to_gcs(blob)

def call_queue_times_api(queue_times_url):
    queue_data = requests.get(url=queue_times_url)
    json_data = queue_data.json()['lands']
    return json_data


def create_json_file(theme_park_id, theme_park_name, project_id, now, json_data,readable_park_name):

    # GCS setup
    bucket_name = environ.get("RAW_DATA_BUCKET")
    storage_client = storage.Client(project=project_id)
    bucket = storage_client.bucket(bucket_name)
    blob_name = f"{theme_park_name}_{theme_park_id}_{now}.json"
    blob = bucket.blob(blob_name)

    # Manipulate data as is and write file to cloud storage in JSONL format for BQ ingestion
    with blob.open("w") as f:
        for land in json_data:
            for ride in land['rides']:
                ride['land'] = str.lower(land['name'])
                ride['park'] = str.lower(readable_park_name)
                f.write(json.dumps(ride) + "\n")
    
    return blob


def write_to_gcs(blob):
    with blob.open("r") as f:
        blob.upload_from_file(f)

def setup(theme_park_id):
    # define variables
    queue_times_url = f'https://queue-times.com/en-US/parks/{theme_park_id}/queue_times.json'
    now = time.strftime("%Y%m%d_%H%M%S")
    project_id = environ.get("GCP_PROJECT")

    # prepare logging client
    client = google.cloud.logging.Client(project=project_id)
    client.setup_logging()

    return project_id,now,queue_times_url