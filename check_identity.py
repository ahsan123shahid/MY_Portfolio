import pyodbc

conn = pyodbc.connect(
    "Driver={ODBC Driver 17 for SQL Server};"
    "Server=AHSAN_SHAHID\\MSSQLSERVER01;"
    "Database=BaraniQuizDB;"
    "Trusted_Connection=yes;"
    "TrustServerCertificate=yes;"
)

cursor = conn.cursor()

for table_name in ['Subject', 'Topic', 'KnowledgeChunk']:
    print(f"\n=== {table_name} table ===")
    cursor.execute(f"""
        SELECT 
            c.name,
            t.name as data_type,
            c.is_nullable,
            c.is_identity,
            COLUMNPROPERTY(OBJECT_ID('{table_name}'), c.name, 'IsIdentity') as identity_status
        FROM sys.columns c
        JOIN sys.types t ON c.user_type_id = t.user_type_id
        WHERE c.object_id = OBJECT_ID('{table_name}')
    """)
    for row in cursor.fetchall():
        print(f"  {row[0]}: {row[1]} (nullable: {row[2]}, is_identity: {row[3]}, identity_status: {row[4]})")

conn.close()
