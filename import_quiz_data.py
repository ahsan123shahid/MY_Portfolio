"""
BaraniQuiz Data Import Script
Reads Excel file and imports data into SQL Server database
"""

import pandas as pd
import pyodbc
from datetime import datetime

# ============================================================
# CONFIGURATION
# ============================================================

EXCEL_FILE = r"C:\Users\ahsan\StudioProjects\myproject\DATABASE-QUIZ-GENERTOR.xlsx"

CONNECTION_STRING = (
    "Driver={ODBC Driver 17 for SQL Server};"
    "Server=AHSAN_SHAHID\\MSSQLSERVER01;"
    "Database=BaraniQuizDB;"
    "Trusted_Connection=yes;"
    "TrustServerCertificate=yes;"
    "Connection Timeout=30;"
)

# ============================================================
# MAIN IMPORT FUNCTION
# ============================================================

def import_quiz_data():
    print("=" * 60)
    print("BaraniQuiz Data Import Script")
    print("=" * 60)
    
    # Step 1: Read Excel file
    print("\n[1/5] Reading Excel file...")
    try:
        df = pd.read_excel(EXCEL_FILE)
        print("     [OK] Excel file loaded successfully!")
        print(f"     [OK] Total rows in Excel: {len(df)}")
        print(f"     [OK] Columns: {list(df.columns)}")
    except Exception as e:
        print(f"     [ERROR] Error reading Excel file: {e}")
        return
    
    # Step 2: Connect to SQL Server
    print("\n[2/5] Connecting to SQL Server...")
    try:
        conn = pyodbc.connect(CONNECTION_STRING)
        cursor = conn.cursor()
        print("     [OK] Connected to SQL Server successfully!")
    except Exception as e:
        print(f"     [ERROR] Error connecting to SQL Server: {e}")
        return
    
    # Step 3: Verify tables exist
    print("\n[3/5] Verifying tables exist...")
    try:
        cursor.execute("""
            SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_NAME IN ('Subject', 'Topic', 'KnowledgeChunk')
        """)
        table_count = cursor.fetchone()[0]
        
        if table_count >= 3:
            print("     [OK] All tables exist!")
        else:
            print("     [WARN] Some tables are missing!")
        
    except Exception as e:
        print(f"     [ERROR] Error verifying tables: {e}")
        conn.close()
        return
    
    # Step 4: Import data
    print("\n[4/5] Importing data into tables...")
    
    try:
        # Get unique subjects
        unique_subjects = df['Subject'].dropna().unique()
        print(f"\n     >> Found {len(unique_subjects)} unique subjects in Excel")
        
        subject_id_map = {}
        
        for subject_name in unique_subjects:
            try:
                # Check if subject exists
                cursor.execute("SELECT SubjectId FROM Subject WHERE Name = ?", (subject_name,))
                row = cursor.fetchone()
                
                if row:
                    subject_id_map[subject_name] = row[0]
                    print(f"        [EXISTS] Subject: {subject_name} (ID: {row[0]})")
                else:
                    # Get max SubjectId for manual ID assignment
                    cursor.execute("SELECT ISNULL(MAX(SubjectId), 0) FROM Subject")
                    max_id = cursor.fetchone()[0]
                    new_id = max_id + 1
                    
                    # Insert new subject with manual ID (Subject table has no identity)
                    cursor.execute(
                        "INSERT INTO Subject (SubjectId, Name) VALUES (?, ?)",
                        (new_id, subject_name)
                    )
                    conn.commit()
                    
                    subject_id_map[subject_name] = new_id
                    print(f"        [INSERTED] Subject: {subject_name} (ID: {new_id})")
                        
            except Exception as e:
                print(f"        [WARN] Error with subject '{subject_name}': {e}")
        
        print(f"\n     [OK] {len(subject_id_map)} subjects processed!")
        
        # Get unique topics per subject
        unique_topics = df.dropna(subset=['Subject', 'Topic']).drop_duplicates(subset=['Subject', 'Topic'])
        print(f"\n     >> Found {len(unique_topics)} unique topics in Excel")
        
        topic_id_map = {}
        
        for _, row in unique_topics.iterrows():
            subject_name = row['Subject']
            topic_name = row['Topic']
            subject_id = subject_id_map.get(subject_name)
            
            if subject_id and pd.notna(topic_name):
                try:
                    # Check if topic exists
                    cursor.execute(
                        "SELECT TopicId FROM Topic WHERE SubjectId = ? AND TopicName = ?",
                        (subject_id, topic_name)
                    )
                    topic_row = cursor.fetchone()
                    
                    if topic_row:
                        topic_id_map[(subject_name, topic_name)] = topic_row[0]
                    else:
                        # Insert new topic WITHOUT TopicId (TopicId has IDENTITY ON)
                        cursor.execute(
                            "INSERT INTO Topic (SubjectId, TopicName) VALUES (?, ?)",
                            (subject_id, topic_name)
                        )
                        conn.commit()
                        
                        cursor.execute(
                            "SELECT TopicId FROM Topic WHERE SubjectId = ? AND TopicName = ?",
                            (subject_id, topic_name)
                        )
                        topic_row = cursor.fetchone()
                        if topic_row:
                            topic_id_map[(subject_name, topic_name)] = topic_row[0]
                            
                except Exception as e:
                    print(f"        [WARN] Error with topic '{topic_name}': {e}")
        
        print(f"     [OK] {len(topic_id_map)} topics processed!")
        
        # Import all rows into KnowledgeChunk
        print(f"\n     >> Importing all {len(df)} rows into KnowledgeChunk...")
        
        rows_imported = 0
        rows_skipped = 0
        
        for _, row in df.iterrows():
            subject_name = row.get('Subject')
            topic_name = row.get('Topic')
            week = row.get('Week', None)
            difficulty = row.get('Difficulty', None)
            content_type = row.get('Type', None)
            content = row.get('Content', None)
            
            subject_id = subject_id_map.get(subject_name)
            
            if subject_id:
                try:
                    # Insert WITHOUT ChunkId (ChunkId has IDENTITY ON)
                    cursor.execute("""
                        INSERT INTO KnowledgeChunk 
                        (SubjectId, TopicName, Week, Difficulty, Type, Content)
                        VALUES (?, ?, ?, ?, ?, ?)
                    """, (
                        subject_id,
                        topic_name if pd.notna(topic_name) else None,
                        int(week) if pd.notna(week) else None,
                        difficulty if pd.notna(difficulty) else None,
                        content_type if pd.notna(content_type) else None,
                        content if pd.notna(content) else None
                    ))
                    conn.commit()
                    rows_imported += 1
                except Exception as e:
                    rows_skipped += 1
                    if rows_skipped <= 5:
                        print(f"        [WARN] Error inserting row: {e}")
        
        print(f"     [OK] {rows_imported} knowledge chunks imported!")
        if rows_skipped > 0:
            print(f"     [WARN] {rows_skipped} rows skipped due to errors!")
    
    except Exception as e:
        print(f"     [ERROR] Error importing data: {e}")
        conn.close()
        return
    
    # Step 5: Show final counts
    print("\n[5/5] Final table row counts...")
    try:
        cursor.execute("SELECT COUNT(*) FROM Subject")
        subject_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM Topic")
        topic_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM KnowledgeChunk")
        chunk_count = cursor.fetchone()[0]
        
        print("\n" + "=" * 50)
        print("              IMPORT SUMMARY")
        print("=" * 50)
        print(f"  Subject table:         {subject_count:>5} rows")
        print(f"  Topic table:           {topic_count:>5} rows")
        print(f"  KnowledgeChunk table:  {chunk_count:>5} rows")
        print("=" * 50)
        
    except Exception as e:
        print(f"     [ERROR] Error getting row counts: {e}")
    
    print("\n[OK] Import completed successfully!")
    cursor.close()
    conn.close()

# ============================================================
# RUN
# ============================================================

if __name__ == "__main__":
    import_quiz_data()
    input("\nPress Enter to exit...")
