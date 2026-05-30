import pyodbc

conn = pyodbc.connect(
    "Driver={ODBC Driver 17 for SQL Server};"
    "Server=AHSAN_SHAHID\\MSSQLSERVER01;"
    "Database=BaraniQuizDB;"
    "Trusted_Connection=yes;"
    "TrustServerCertificate=yes;"
)

cursor = conn.cursor()

print("=== Checking Subject table triggers ===")
cursor.execute("""
    SELECT t.name, m.definition
    FROM sys.triggers t
    JOIN sys.sql_modules m ON t.object_id = m.object_id
    WHERE t.parent_id = OBJECT_ID('Subject')
""")
triggers = cursor.fetchall()
if triggers:
    for t in triggers:
        print(f"Trigger: {t[0]}")
        print(f"Definition: {t[1]}")
else:
    print("No triggers on Subject table")

print("\n=== Checking Subject table constraints ===")
cursor.execute("""
    SELECT cc.name, cc.type_desc, cc.definition
    FROM sys.check_constraints cc
    WHERE cc.parent_object_id = OBJECT_ID('Subject')
""")
constraints = cursor.fetchall()
if constraints:
    for c in constraints:
        print(f"Constraint: {c[0]} - {c[1]}: {c[2]}")
else:
    print("No check constraints")

print("\n=== Trying direct INSERT ===")
try:
    cursor.execute("INSERT INTO Subject (Name) VALUES ('Test Subject')")
    conn.commit()
    print("[OK] Insert successful!")
    
    # Delete the test
    cursor.execute("DELETE FROM Subject WHERE Name = 'Test Subject'")
    conn.commit()
    print("[OK] Test subject deleted!")
except Exception as e:
    print(f"[ERROR] {e}")

conn.close()
