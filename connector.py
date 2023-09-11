import pandas as pd
import psycopg2
from sqlalchemy import create_engine


class Connector:

    def __init__(self) -> None:
        self.db_params = {
            'host': 'localhost',
            'database': 'nimble',
            'user': 'admin',
            'password': 'admin',
            'port': '8000'}
        
    def execute_query(self, sql:str) -> pd.DataFrame:
        try:
            # Create a SQLAlchemy engine
            conn_str = f"postgresql://{self.db_params['user']}:{self.db_params['password']}@{self.db_params['host']}:{self.db_params['port']}/{self.db_params['database']}"
            engine = create_engine(conn_str)

            # Use pandas to read the SQL query result directly into a DataFrame
            df = pd.read_sql_query(sql, engine)
            return df
        except Exception as e:
            print(f"Error executing query: {e}")

    def create_table(self, sql:str) -> None:
        try:
            # Connect to the PostgreSQL database
            conn = psycopg2.connect(**self.db_params)

            # Create a cursor object
            cursor = conn.cursor()

            # Execute the SQL query to create the table
            cursor.execute(sql)

            # Commit the transaction to save changes
            conn.commit()

            # Close the cursor and connection
            cursor.close()
            conn.close()

            print("Table created successfully")

        except (Exception, psycopg2.Error) as error:
            print("Error creating table:", error)


    def store_dataframe(self, df_:pd.DataFrame, name:str) -> bool:
        engine = create_engine(f'postgresql+psycopg2://{self.db_params["user"]}:{self.db_params["password"]}@{self.db_params["host"]}:{self.db_params["port"]}/{self.db_params["database"]}')
        df_.to_sql(name, engine, if_exists='replace', index=False)




