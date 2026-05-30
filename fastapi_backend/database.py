from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# ─── DB Configuration ───────────────────────────────────────────────────────
SQL_SERVER = "AHSAN_SHAHID\\MSSQLSERVER01"
DATABASE   = "BaraniQuizDB"

SQLALCHEMY_DATABASE_URL = (
    f"mssql+pyodbc://{SQL_SERVER}/{DATABASE}"
    f"?trusted_connection=yes&driver=ODBC+Driver+17+for+SQL+Server"
)

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"trust_server_certificate": True},
    pool_pre_ping=True,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()