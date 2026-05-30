from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db
from models import KnowledgeChunk
from schemas import NoteChunkResponse

router = APIRouter(prefix="/api/Notes", tags=["notes"])

@router.get("/{subject_id}/{topic_name}")
def get_notes(subject_id: int, topic_name: str, db: Session = Depends(get_db)):
    chunks = db.query(KnowledgeChunk).filter(
        KnowledgeChunk.SubjectId == subject_id,
        KnowledgeChunk.TopicName == topic_name
    ).order_by(
        KnowledgeChunk.Difficulty,
        KnowledgeChunk.Type
    ).all()
    
    return [{
        "chunkId": c.ChunkId,
        "content": c.Content,
        "difficulty": c.Difficulty or "",
        "type": c.Type or "",
        "week": c.Week or 0
    } for c in chunks]