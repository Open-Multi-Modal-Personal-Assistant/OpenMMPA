from firebase_functions import https_fn, options
from firebase_admin import initialize_app, storage
import datetime
import firebase_admin
import json
import os

from google.cloud import texttospeech

@https_fn.on_request(timeout_sec=300, memory=options.MemoryOption.MB_512)
def tts(req: https_fn.Request) -> https_fn.Response:
    """Synthesizes speech from the input string of text or ssml.
    Returns:
        Encoded audio file in the body.
    Note: ssml must be well-formed according to:
        https://www.w3.org/TR/speech-synthesis/
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

    if request_json and 'data' in request_json:
        request_json = request_json['data']

    if request_json and 'language_code' in request_json:
        language_code = request_json['language_code']
    elif request_args and 'language_code' in request_args:
        language_code = request_args['language_code']
    elif request_form and 'language_code' in request_form:
        language_code = request_form['language_code']
    else:
        language_code = os.environ.get('LANGUAGE_CODE', 'en-US')

    if request_json and 'text' in request_json:
        text = request_json['text']
    elif request_args and 'text' in request_args:
        text = request_args['text']
    elif request_form and 'text' in request_form:
        text = request_form['text']
    else:
        text = ''

    # Instantiates a client
    client = texttospeech.TextToSpeechClient()

    # Set the text input to be synthesized
    synthesis_input = texttospeech.SynthesisInput(text=text)

    # Build the voice request, select the language code ("en-US") and the ssml
    # voice gender ("neutral")
    voice = texttospeech.VoiceSelectionParams(
        language_code=language_code, ssml_gender=texttospeech.SsmlVoiceGender.NEUTRAL
    )

    # Select the type of audio file you want returned
    audio_config = texttospeech.AudioConfig(
        audio_encoding=texttospeech.AudioEncoding.OGG_OPUS
    )

    # Perform the text-to-speech request on the text input with the selected
    # voice parameters and audio file type
    response = client.synthesize_speech(
        input=synthesis_input, voice=voice, audio_config=audio_config
    )

    now = datetime.datetime.now()
    file_name = now.strftime('tts_%m%d%Y_%H%M%S.ogg')
    project_id = 'open-mmpa'
    bucket = storage.bucket(f'{project_id}.appspot.com')
    synth_blob = bucket.blob(file_name)
    synth_blob.upload_from_string(response.audio_content, content_type='audio/ogg')
    synth_file_name = synth_blob.public_url.split('/')[-1].split('?')[0]

    return https_fn.Response(
        json.dumps(dict(data=[synth_file_name])),
        status=200,
        content_type='application/json',
    )
