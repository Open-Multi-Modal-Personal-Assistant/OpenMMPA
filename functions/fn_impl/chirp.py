from firebase_functions import https_fn, options
from firebase_admin import initialize_app, storage
import firebase_admin
import google.cloud.logging
import json
import logging

from google.api_core.client_options import ClientOptions
from google.cloud.speech_v2 import SpeechClient
from google.cloud.speech_v2.types import cloud_speech

def transcribe_chirp_auto_detect_language(
    project_id: str,
    region: str,
    audio_bytes: str,
) -> cloud_speech.RecognizeResponse:
    """Transcribe an audio file and auto-detect spoken language using Chirp.

    Please see https://cloud.google.com/speech-to-text/v2/docs/encoding for more
    information on which audio encodings are supported.
    """
    # Instantiates a client
    client = SpeechClient(
        client_options=ClientOptions(
            api_endpoint=f"{region}-speech.googleapis.com",
        )
    )

    config = cloud_speech.RecognitionConfig(
        auto_decoding_config=cloud_speech.AutoDetectDecodingConfig(),
        language_codes=["auto"],  # Set language code to auto to detect language.
        model="chirp",
    )

    request = cloud_speech.RecognizeRequest(
        recognizer=f"projects/{project_id}/locations/{region}/recognizers/_",
        config=config,
        content=audio_bytes,
    )

    # Transcribes the audio into text
    response = client.recognize(request=request)

    transcripts = []
    for result in response.results:
        transcripts.append(result.alternatives[0].transcript.strip())
        transcripts.append(result.language_code)

    return transcripts

@https_fn.on_request(timeout_sec=300, memory=options.MemoryOption.MB_512)
def chirp(req: https_fn.Request) -> https_fn.Response:
    """Chirp audio to text.
    Args:
        request (flask.Request): Carries the PCM16 audio with WAV header as body.
        <https://flask.palletsprojects.com/en/1.1.x/api/#incoming-request-data>
    Returns:
        Alternating list of transcript and the language of the preceding transcript.
        <https://flask.palletsprojects.com/en/1.1.x/api/#flask.make_response>.
    """
    # Set CORS headers for the preflight request
    if req.method == 'OPTIONS':
        # Allows GET requests from any origin with the Content-Type
        # header and caches preflight response for an 3600s
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }

        return ('', 204, headers)

    if not firebase_admin._apps:
        initialize_app()

    request_json = req.get_json(silent=True)
    request_args = req.args
    request_form = req.form

    transcripts = []
    project_id = 'open-mmpa'
    region = 'us-central1'

    if request_json and 'data' in request_json and 'recording_file_name' in request_json['data']:
        recording_file_name = request_json['data']['recording_file_name']
    elif request_args and 'recording_file_name' in request_args:
        recording_file_name = request_args['recording_file_name']
    elif request_form and 'recording_file_name' in request_form:
        recording_file_name = request_form['recording_file_name']
    else:
        recording_file_name = None

    if not recording_file_name:
        return transcripts, 400

    try:
        bucket = storage.bucket(f'{project_id}.appspot.com')
        blob = bucket.blob(recording_file_name)
        wav_bytes = blob.download_as_bytes()
        transcripts = transcribe_chirp_auto_detect_language(project_id, region, wav_bytes)
    except Exception as e:
        client = google.cloud.logging.Client()
        client.setup_logging()
        logging.exception(e)
        return transcripts, 500

    return https_fn.Response(
        json.dumps(dict(data=transcripts)),
        status=200,
        content_type='application/json',
    )
