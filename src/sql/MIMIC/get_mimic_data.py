import os
from dotenv import load_dotenv
from google.cloud import bigquery
import pandas as pd
from argparse import ArgumentParser


def create_aux_dataset(client, project_id):
    # Create 'aux' dataset if it doesn't exist
    dataset_id = f"{project_id}.my_MIMIC"
    dataset = bigquery.Dataset(dataset_id)
    dataset.location = "US"
    print(f"Creating dataset {dataset_id}...")
    dataset = client.create_dataset(dataset, exists_ok=True)


def create_aux_tables(client,
                      project_id,
                      script_filenames=['aux_tables/pivoted_codes.sql',
                                        'aux_tables/pivoted_comorbidities.sql']):
    # Run SQL scripts in order
    for script_filename in script_filenames:
        print(f"Executing {script_filename}...")
        with open(script_filename, 'r') as script_file:
            script = script_file.read().replace('db_name', project_id)
            job = client.query(script)
            job.result()  # Wait for the query to complete


def create_main_table(client, project_id, destination):
    print(f"Creating main table {destination}...")
    with open('main.SQL', 'r') as script_file:
        script = script_file.read().replace('db_name', project_id)
        df = client.query(script).to_dataframe()
        df.to_csv(destination, index=False)


def main(args):
    # Load environment variables
    load_dotenv()
    project_id = os.getenv('PROJECT_ID')
    # Set up BigQuery client using default SDK credentials
    client = bigquery.Client(project=project_id)
    # create the aux dataset
    create_aux_dataset(client, project_id)
    # create the aux tables
    create_aux_tables(client, project_id)
    # create the main table
    create_main_table(client, project_id, args.destination)


if __name__ == "__main__":
    # parse the arguments
    parser = ArgumentParser()
    parser.add_argument(
        "-d", "--destination", default='../../../data/MIMIC_data.csv', help="output csv file")
    args = parser.parse_args()
    main(args)
