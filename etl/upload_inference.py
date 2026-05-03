import pandas as pd
import time
import os
import psycopg2
from pgvector.psycopg2 import register_vector
import mlflow
import torch_directml
from sentence_transformers import SentenceTransformer
import numpy as np


mlflow.set_tracking_uri("http://localhost:5000")
mlflow.set_experiment("ReelSense Inference Upload")

with mlflow.start_run(run_name="Upload Inference Results") as run:
    start_time = time.time()
    model_path = "U:\\CODE\\ReelSense\\etl\\models\\reelsense-movie-embeddings"
    mlflow.log_param("model_path", model_path)
    mlflow.log_param("embedding_dimension", 384)

    print("Loading model...")
    model = SentenceTransformer(model_path)

    print("loading dataset...")
    movies = pd.read_csv("U:\\CODE\\ReelSense\\data\\movies_enriched.csv")

    columnas = [
        "name",
        "description",
        "tagline",
        "main_actors",
        "main_directors",
        "main_genres",
        "main_themes",
    ]
    movies[columnas] = movies[columnas].fillna("")

    movies["meta_texto"] = movies[
        ["name", "main_actors", "main_directors", "main_genres", "main_themes"]
    ].agg(" ".join, axis=1)
    movies["plot_texto"] = movies[["description", "tagline"]].agg(" ".join, axis=1)


    mlflow.log_param("num_movies", len(movies))

    print("Generating embeddings...")
    meta_embeddings = model.encode(
        movies["meta_texto"].tolist(),
        show_progress_bar=True,
        batch_size=512,        # push it higher on CPU
        convert_to_numpy=True  # skip any tensor overhead
    )
    plot_embeddings = model.encode(movies["plot_texto"].tolist(),
        show_progress_bar=True, 
        batch_size=512, 
        convert_to_numpy=True
    )
    db_url = os.environ.get("DATABASE_URL")

    conn = psycopg2.connect(db_url)
    register_vector(conn)

    cur = conn.cursor()

    cur.execute("CREATE EXTENSION IF NOT EXISTS vector;")
    cur.execute("DROP TABLE IF EXISTS movie_embeddings;")
    cur.execute("""
    CREATE TABLE movie_embeddings (
        id SERIAL PRIMARY KEY,
        movie_id INT,
        name TEXT,
        meta_embedding VECTOR(384),
        plot_embedding VECTOR(384),
        poster_link TEXT
    );
""")
    
    rows = list(zip(movies['id'].tolist(),
                    movies['name'].tolist(),
                    [np.array(e) for e in meta_embeddings],
                    [np.array(e) for e in plot_embeddings],
                    movies['link'].tolist()))



    cur.executemany(
    "INSERT INTO movie_embeddings (movie_id, name, meta_embedding, plot_embedding, poster_link) VALUES (%s, %s, %s, %s, %s)",
    rows
)
    conn.commit()
    cur.close()
    conn.close()
    
    # 4. Cerramos el log de rendimiento
    end_time = time.time()
    mlflow.log_metric("processing_time_seconds", end_time - start_time)
    
    print("¡Catálogo vectorizado y trackeado en MLflow con éxito!")
