import pandas as pd
from sentence_transformers import SentenceTransformer
import psycopg2
from pgvector.psycopg2 import register_vector


model= SentenceTransformer('all-MiniLM-L6-v2')
conn = psycopg2.connect(