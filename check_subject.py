import pyodbc

conn = pyodbc.connect(
    "Driver={ODBC Driver 17 for SQL Server};"
    "Server=AHSAN_SHAHID\\MSSQLSERVER01;"
    "Database=BaraniQuizDB;"
    "Trusted_Connection=yes;"
    "TrustServerCertificate=yes;"
)

cursor = conn.cursor()

print("=== Subject table full structure ===")
cursor.execute("""
    SELECT 
        c.name,
        t.name as data_type,
        c.max_length,
        c.precision,
        c.scale,
        c.is_nullable,
        c.is_identity,
        CASE WHEN i.is_primary_key = 1 THEN 'YES' ELSE 'NO' END as is_primary_key
    FROM sys.columns c
    JOIN sys.types t ON c.user_type_id = t.user_type_id
    LEFT JOIN sys.indexes i ON c.object_id = i.object_id AND c.column_id = i.index_id
    WHERE c.object_id = OBJECT_ID('Subject')
""")
print("Columns:")
for row in cursor.fetchall():
    print(f"  {row[0]}: {row[1]} (nullable: {row[5]}, identity: {row[6]}, pk: {row[7]})")

print("\n=== Check Subject table data ===")
cursor.execute("SELECT * FROM Subject")
rows = cursor.fetchall()
print(f"Current rows in Subject table: {len(rows)}")
for row in rows:
    print(f"  {row}")

conn.close()
