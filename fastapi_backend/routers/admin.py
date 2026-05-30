"""
admin.py — Admin CRUD Router
==============================
Endpoints:
  GET    /api/admin/stats
  GET    /api/admin/subjects
  POST   /api/admin/subjects
  DELETE /api/admin/subjects/{subject_id}
  GET    /api/admin/subjects/{subject_id}/topics
  POST   /api/admin/topics
  DELETE /api/admin/topics/{topic_id}
  GET    /api/admin/questions/{topic_name}
  DELETE /api/admin/questions/{question_id}
"""

import urllib.parse

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import get_db
from models import KnowledgeChunk, Question, Quiz, Subject, Topic

router = APIRouter(prefix="/api/admin", tags=["admin"])


# ════════════════════════════════════════════════════════════════════════════
# STATS
# ════════════════════════════════════════════════════════════════════════════

@router.get("/stats")
def get_stats(db: Session = Depends(get_db)):
    return {
        "totalSubjects": db.query(Subject).count(),
        "totalTopics":   db.query(Topic).count(),
        "totalQuestions": db.query(Question).count(),
    }


# ════════════════════════════════════════════════════════════════════════════
# SUBJECTS
# ════════════════════════════════════════════════════════════════════════════

@router.get("/subjects")
def get_subjects(db: Session = Depends(get_db)):
    subjects = db.query(Subject).all()
    result = []
    for s in subjects:
        topic_count = db.query(Topic).filter(Topic.SubjectId == s.SubjectId).count()
        # Count all questions for this subject
        q_count = (
            db.query(Question)
            .join(Quiz, Question.QuizId == Quiz.QuizId)
            .filter(Quiz.SubjectId == s.SubjectId)
            .count()
        )
        result.append({
            "subjectId":     s.SubjectId,
            "name":          s.Name,
            "topicCount":    topic_count,
            "questionCount": q_count,
        })
    return result


@router.post("/subjects")
def add_subject(name: str, db: Session = Depends(get_db)):
    name = name.strip()
    if not name:
        raise HTTPException(status_code=400, detail="Subject name cannot be empty.")
    existing = db.query(Subject).filter(Subject.Name == name).first()
    if existing:
        raise HTTPException(status_code=400, detail="A subject with this name already exists.")
    s = Subject(Name=name)
    db.add(s)
    db.commit()
    db.refresh(s)
    return {"success": True, "subjectId": s.SubjectId, "name": s.Name}


@router.delete("/subjects/{subject_id}")
def delete_subject(subject_id: int, db: Session = Depends(get_db)):
    s = db.query(Subject).filter(Subject.SubjectId == subject_id).first()
    if not s:
        raise HTTPException(status_code=404, detail="Subject not found.")

    # Delete quizzes + questions for this subject
    quizzes = db.query(Quiz).filter(Quiz.SubjectId == subject_id).all()
    for quiz in quizzes:
        db.query(Question).filter(Question.QuizId == quiz.QuizId).delete()
        db.delete(quiz)
    db.commit()

    # Topics cascade-delete chunks via FK
    db.query(Topic).filter(Topic.SubjectId == subject_id).delete()
    db.commit()

    db.delete(s)
    db.commit()
    return {"success": True}


# ════════════════════════════════════════════════════════════════════════════
# TOPICS
# ════════════════════════════════════════════════════════════════════════════

@router.get("/subjects/{subject_id}/topics")
def get_topics(subject_id: int, db: Session = Depends(get_db)):
    topics = db.query(Topic).filter(Topic.SubjectId == subject_id).all()
    result = []
    for t in topics:
        q_count = (
            db.query(Question)
            .join(Quiz, Question.QuizId == Quiz.QuizId)
            .filter(Quiz.TopicName == t.TopicName, Quiz.SubjectId == subject_id)
            .count()
        )
        chunk_count = (
            db.query(KnowledgeChunk)
            .filter(
                KnowledgeChunk.SubjectId == subject_id,
                KnowledgeChunk.TopicName == t.TopicName,
                )
            .count()
        )
        result.append({
            "topicId":       t.TopicId,
            "topicName":     t.TopicName,
            "questionCount": q_count,
            "hasContent":    chunk_count > 0,
        })
    return result


@router.post("/topics")
def add_topic(subject_id: int, topic_name: str, db: Session = Depends(get_db)):
    topic_name = topic_name.strip()
    if not topic_name:
        raise HTTPException(status_code=400, detail="Topic name cannot be empty.")
    existing = db.query(Topic).filter(
        Topic.SubjectId == subject_id,
        Topic.TopicName == topic_name,
        ).first()
    if existing:
        return {"success": True, "topicId": existing.TopicId, "topicName": existing.TopicName, "new": False}
    t = Topic(SubjectId=subject_id, TopicName=topic_name)
    db.add(t)
    db.commit()
    db.refresh(t)
    return {"success": True, "topicId": t.TopicId, "topicName": t.TopicName, "new": True}


@router.delete("/topics/{topic_id}")
def delete_topic(topic_id: int, db: Session = Depends(get_db)):
    topic = db.query(Topic).filter(Topic.TopicId == topic_id).first()
    if not topic:
        raise HTTPException(status_code=404, detail="Topic not found.")

    # Delete quizzes + questions with this topic name in the same subject
    quizzes = db.query(Quiz).filter(
        Quiz.SubjectId == topic.SubjectId,
        Quiz.TopicName == topic.TopicName,
        ).all()
    for quiz in quizzes:
        db.query(Question).filter(Question.QuizId == quiz.QuizId).delete()
        db.delete(quiz)
    db.commit()

    # KnowledgeChunks cascade via FK, but also do explicit delete for safety
    db.query(KnowledgeChunk).filter(
        KnowledgeChunk.SubjectId == topic.SubjectId,
        KnowledgeChunk.TopicName == topic.TopicName,
        ).delete()
    db.commit()

    db.delete(topic)
    db.commit()
    return {"success": True}


# ════════════════════════════════════════════════════════════════════════════
# QUESTIONS
# ════════════════════════════════════════════════════════════════════════════

@router.get("/questions/{topic_name}")
def get_questions(
        topic_name: str,
        subject_id: int = None,
        difficulty: str = None,
        qtype: str = None,
        db: Session = Depends(get_db),
):
    decoded = urllib.parse.unquote(topic_name)
    query   = db.query(Question).join(Quiz, Question.QuizId == Quiz.QuizId).filter(
        Quiz.TopicName == decoded
    )
    if subject_id:
        query = query.filter(Quiz.SubjectId == subject_id)
    if difficulty:
        query = query.filter(Quiz.Difficulty == difficulty)
    if qtype:
        query = query.filter(Quiz.QuizType == qtype)

    questions = query.all()
    return [
        {
            "questionId":   q.QuestionId,
            "quizId":       q.QuizId,
            "questionText": q.QuestionText,
            "optionA":      q.OptionA,
            "optionB":      q.OptionB,
            "optionC":      q.OptionC,
            "optionD":      q.OptionD,
            "correctOption": q.CorrectOption,
            "explanation":  q.Explanation,
            "difficulty":   q.quiz.Difficulty if q.quiz else "",
            "type":         q.quiz.QuizType   if q.quiz else "",
        }
        for q in questions
    ]


@router.delete("/questions/{question_id}")
def delete_question(question_id: int, db: Session = Depends(get_db)):
    q = db.query(Question).filter(Question.QuestionId == question_id).first()
    if not q:
        raise HTTPException(status_code=404, detail="Question not found.")
    db.delete(q)
    db.commit()
    return {"success": True}