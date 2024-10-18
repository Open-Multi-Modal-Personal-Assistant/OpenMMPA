from firebase_functions import https_fn , options, storage_fn
from firebase_admin import initialize_app, storage
import firebase_admin
import google.cloud.logging
import json
import logging
import vertexai

from vertexai.language_models import TextEmbeddingInput, TextEmbeddingModel
from vertexai.vision_models import Image as VMImage
from vertexai.vision_models import MultiModalEmbeddingModel, MultiModalEmbeddingResponse
from vertexai.vision_models import Video as VMVideo
from vertexai.vision_models import VideoSegmentConfig


@https_fn.on_request()
@storage_fn.on_object_finalized(timeout_sec=300, memory=options.MemoryOption.MB_512)
def embed(req: https_fn.Request) -> https_fn.Response:
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

    if request_json and 'image_path' in request_json:
        image_path = request_json['image_path']
    elif request_args and 'image_path' in request_args:
        image_path = request_args['image_path']
    elif request_form and 'image_path' in request_form:
        image_path = request_form['image_path']
    else:
        image_path = None

    if request_json and 'video_path' in request_json:
        video_path = request_json['video_path']
    elif request_args and 'video_path' in request_args:
        video_path = request_args['video_path']
    elif request_form and 'video_path' in request_form:
        video_path = request_form['video_path']
    else:
        video_path = None

    if request_json and 'text' in request_json:
        text = request_json['text']
    elif request_args and 'text' in request_args:
        text = request_args['text']
    elif request_form and 'text' in request_form:
        text = request_form['text']
    else:
        text = None

    project_id = 'open-mmpa'
    region = 'us-central1'
    vertexai.init(project=project_id, location=region)

    embeddings = []
    if text:
        # Multi-lingual text embedding
        # The task type for embedding. Check the available tasks in the model's documentation.
        task = "RETRIEVAL_DOCUMENT"
        multi_lingual_embedding_model = TextEmbeddingModel.from_pretrained("text-embedding-004")
        inputs = [TextEmbeddingInput(text, task)]
        kwargs = dict(output_dimensionality=768)
        try:
            text_embeddings = multi_lingual_embedding_model.get_embeddings(inputs, **kwargs)
            embeddings.append([embedding.values for embedding in text_embeddings])
        except Exception as e:
            client = google.cloud.logging.Client()
            client.setup_logging()
            logging.exception(e)
            return embeddings, 500

    if image_path or video_path:
        multi_modal_embedding_model = MultiModalEmbeddingModel.from_pretrained("multimodalembedding")

        image = VMImage.load_from_file(image_path) if image_path else None
        video = VMVideo.load_from_file(video_path) if video_path else None
        dimension = 1408

        try:
            multi_modal_embeddings = multi_modal_embedding_model.get_embeddings(
                image=image,
                video=video,
                video_segment_config=VideoSegmentConfig(),
                contextual_text=text,
                dimension=dimension,
            )

            if multi_modal_embeddings:
                embeddings.append(multi_modal_embeddings.image_embedding if image else [])
                if video and multi_modal_embeddings.video_embeddings:
                    for video_embedding in multi_modal_embeddings.video_embeddings:
                        embeddings.append(video_embedding.embedding)
        except Exception as e:
            client = google.cloud.logging.Client()
            client.setup_logging()
            logging.exception(e)
            return embeddings, 500

    return https_fn.Response(
        json.dumps(dict(data=embeddings)),
        status=200,
        content_type='application/json',
    )
