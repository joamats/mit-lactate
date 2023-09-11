import argparse
import pandas as pd
import numpy as np

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--sql", help="Insert your SQL query's path")
    parser.add_argument("--destination", help="Insert your pulled data's destination path")

    return parser.parse_args()

# Run Query to get a DataFrame from BigQuery
def run_query(sql_query_path):

    # Access data using Google BigQuery.
    import os
    from dotenv import load_dotenv

    # Load env file 
    load_dotenv()

    # Get GCP's secrets
    KEYS_FILE = os.getenv("KEYS_FILE")
    PROJECT_ID = os.getenv("PROJECT_ID")

    # Set environment variables
    os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = KEYS_FILE

    # Establish connection with BigQuery
    from google.cloud import bigquery
    BigQuery_client = bigquery.Client()

    # Read query
    with open(sql_query_path, 'r') as fd:
        query = fd.read()

    # Replace the project id by the coder's project id in GCP
    my_query = query.replace("physionet-data", PROJECT_ID).replace("db_name", PROJECT_ID, -1)

    # Make request to BigQuery with our query
    df = BigQuery_client.query(my_query).to_dataframe()

    return df

if __name__ == '__main__':

    args = parse_args()
    df = run_query(sql_query_path = args.sql)
    
    df.to_csv(args.destination)