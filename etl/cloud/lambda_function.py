import os
import json
import time
import boto3
import psycopg2
import numpy as np
from pgvector.psycopg2 import register_vector

sagemaker_runtime = boto3.client('sagemaker-runtime')

def get_conn():
    conn = psycopg2.connect(
        host=os.environ['host'],
        port=5432,
        dbname=os.environ['dbname'],
        user=os.environ['username'],
        password=os.environ['password'],
        sslmode='require'
    )
    register_vector(conn)
    return conn

def lambda_handler(event, context):
    t0 = time.time()

    if event.get('queryStringParameters'):
        params = event['queryStringParameters']
        query = params.get('query', '')
    elif event.get('body'):
        body = json.loads(event['body'])
        query = body.get('query', '')
    else:
        query = event.get('query', '')

    response = sagemaker_runtime.invoke_endpoint(
        EndpointName='final-reelsense-endpoint',
        ContentType='application/json',
        Body=json.dumps({'inputs': query})
    )
    print(f"[1] SageMaker: {time.time() - t0:.2f}s")

    raw = json.loads(response['Body'].read())
    token_embeddings = np.array(raw[0])
    embedding = np.mean(token_embeddings, axis=0)
    embedding_str = '[' + ','.join(map(str, embedding.tolist())) + ']'

    conn = get_conn()
    cur = conn.cursor()
    print(f"[2] Conexión RDS: {time.time() - t0:.2f}s")

    cur.execute("""
        SELECT movie_id, name, poster_link,
            1 - (meta_embedding <=> %s::vector) AS score
        FROM movie_embeddings
        WHERE name IS NOT NULL 
            AND LENGTH(TRIM(name)) > 2
            AND poster_link IS NOT NULL
            AND poster_link != 'NaN'
        ORDER BY meta_embedding <=> %s::vector
        LIMIT 50;
    """, (embedding_str, embedding_str))
    meta_results = {r[0]: {'movie_id': r[0], 'name': r[1], 'poster': r[2], 'meta_score': r[3]} for r in cur.fetchall()}

    cur.execute("""
        SELECT movie_id, name, poster_link,
            1 - (plot_embedding <=> %s::vector) AS score
        FROM movie_embeddings
        WHERE name IS NOT NULL 
            AND LENGTH(TRIM(name)) > 2
            AND poster_link IS NOT NULL
            AND poster_link != 'NaN'
        ORDER BY plot_embedding <=> %s::vector
        LIMIT 50;
    """, (embedding_str, embedding_str))
    plot_results = {r[0]: {'movie_id': r[0], 'name': r[1], 'poster': r[2], 'plot_score': r[3]} for r in cur.fetchall()}

    print(f"[3] Queries pgvector: {time.time() - t0:.2f}s")

    combined = {}
    for movie_id, data in meta_results.items():
        combined[movie_id] = {**data, 'meta_score': data['meta_score'], 'plot_score': None}

    for movie_id, data in plot_results.items():
        if movie_id in combined:
            combined[movie_id]['plot_score'] = data['plot_score']
        else:
            combined[movie_id] = {**data, 'meta_score': None, 'plot_score': data['plot_score']}

    # Calcular score normalizado
    for movie_id, data in combined.items():
        meta = data.get('meta_score') or 0
        plot = data.get('plot_score') or 0
    
        if data['meta_score'] and data['plot_score']:
        # Aparece en ambos — score completo
            data['score'] = 0.4 * meta + 0.6 * plot
        elif data['meta_score']:
            # Solo en meta — normalizar a escala completa
            data['score'] = meta
        else:
        # Solo en plot — normalizar a escala completa
            data['score'] = plot
    results = sorted(combined.values(), key=lambda x: x['score'], reverse=True)[:10]
    results = [{'movie_id': r['movie_id'], 'name': r['name'], 'poster': r['poster'], 'score': round(float(r['score']), 3)} for r in results]

    cur.close()
    conn.close()

    print(f"[4] Total: {time.time() - t0:.2f}s")

    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json'
        },
        'body': json.dumps(results)
    }