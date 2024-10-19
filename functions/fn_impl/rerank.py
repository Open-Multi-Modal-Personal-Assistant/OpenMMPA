from firebase_functions import https_fn, options
from firebase_admin import initialize_app
import firebase_admin
import json

from google.cloud import discoveryengine_v1beta as discoveryengine

@https_fn.on_request(timeout_sec=300, memory=options.MemoryOption.MB_512)
def rerank(req: https_fn.Request) -> https_fn.Response:
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

    if request_json and 'top_n' in request_json:
        top_n = request_json['top_n']
    elif request_args and 'top_n' in request_args:
        top_n = request_args['top_n']
    elif request_form and 'top_n' in request_form:
        top_n = request_form['top_n']
    else:
        top_n = 10

    if request_json and 'query' in request_json:
        query = request_json['query']
    elif request_args and 'query' in request_args:
        query = request_args['query']
    elif request_form and 'query' in request_form:
        query = request_form['query']
    else:
        query = ''

    if not query:
        return [], 400

    if request_json and 'records' in request_json:
        records = request_json['records']
    elif request_args and 'records' in request_args:
        records = request_args['records']
    elif request_form and 'records' in request_form:
        records = request_form['records']
    else:
        records = []

    if not records:
        return [], 400

    ranking_records = []
    for record in records:
        ranking_records.append(
            discoveryengine.RankingRecord(
                id=record['id'],
                title=record['title'],
                content=record['content'],
            )
        )

    project_id = 'open-mmpa'
    region = 'us-central1'
    client = discoveryengine.RankServiceClient()

    # The full resource name of the ranking config.
    # Format: projects/{project_id}/locations/{location}/rankingConfigs/default_ranking_config
    ranking_config = client.ranking_config_path(
        project=project_id,
        location=region,
        ranking_config="default_ranking_config",
    )
    # https://cloud.google.com/generative-ai-app-builder/docs/ranking#models
    # semantic-ranker-512-003, Text (25 languages)
    request = discoveryengine.RankRequest(
        ranking_config=ranking_config,
        model="semantic-ranker-512@latest",
        top_n=top_n,
        query=query,
        records=ranking_records,
    )

    response = client.rank(request=request)
    rerankings = []
    for item in response.records:
        rerankings.append(dict(
            id=item.id,
            score=item.score,
        ))

    return https_fn.Response(
        json.dumps(dict(data=rerankings)),
        status=200,
        content_type='application/json',
    )
