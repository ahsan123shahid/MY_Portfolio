from dotenv import load_dotenv
import os

load_dotenv()

COHERE_API_KEY = os.getenv("COHERE_API_KEY")
DATABASE_URL = "mssql+pyodbc://AHSAN_SHAHID\\MSSQLSERVER01/BaraniQuizDB?trusted_connection=yes&driver=ODBC+Driver+17+for+SQL+Server"