from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db
from models import Subject, Topic
from schemas import SubjectResponse, TopicResponse

router = APIRouter(prefix="/api/subject", tags=["subjects"])

@router.get("")
def get_subjects(db: Session = Depends(get_db)):
    subjects = db.query(Subject).all()
    return [{"subjectId": s.SubjectId, "name": s.Name} for s in subjects]

@router.get("/{subject_id}/topics")
def get_topics(subject_id: int, db: Session = Depends(get_db)):
    topics = db.query(Topic).filter(Topic.SubjectId == subject_id).all()
    return [{"topicId": t.TopicId, "topicName": t.TopicName} for t in topics]