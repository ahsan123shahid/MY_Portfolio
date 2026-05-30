import pyodbc

conn = pyodbc.connect(
    "Driver={ODBC Driver 17 for SQL Server};"
    "Server=AHSAN_SHAHID\\MSSQLSERVER01;"
    "Database=BaraniQuizDB;"
    "Trusted_Connection=yes;"
    "TrustServerCertificate=yes;"
)

cursor = conn.cursor()

print("=== Existing Tables ===")
cursor.execute("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'")
for row in cursor.fetchall():
    print(f"  - {row[0]}")

print("\n=== Table Structures ===")
for table_name in ['Subject', 'Topic', 'KnowledgeChunk']:
    try:
        print(f"\n{table_name}:")
        cursor.execute(f"SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '{table_name}'")
        for row in cursor.fetchall():
            print(f"  - {row[0]}: {row[1]}")
    except:
        print(f"  Table '{table_name}' does not exist")

conn.close()
