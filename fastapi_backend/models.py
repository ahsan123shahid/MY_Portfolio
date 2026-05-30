from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from database import Base


class User(Base):
    __tablename__ = "Users"
    Id       = Column(Integer, primary_key=True, index=True, autoincrement=True)
    Name     = Column(String(200))
    Email    = Column(String(200), unique=True, index=True)
    Password = Column(String(500))
    Role     = Column(String(50), default="student")


class Subject(Base):
    __tablename__ = "Subject"
    SubjectId = Column(Integer, primary_key=True, index=True, autoincrement=True)
    Name      = Column(String(200))

    topics = relationship("Topic", back_populates="subject", cascade="all, delete-orphan")


class Topic(Base):
    __tablename__ = "Topic"
    TopicId   = Column(Integer, primary_key=True, index=True, autoincrement=True)
    SubjectId = Column(Integer, ForeignKey("Subject.SubjectId", ondelete="CASCADE"))
    TopicName = Column(String(300))

    subject          = relationship("Subject", back_populates="topics")
    knowledge_chunks = relationship("KnowledgeChunk", back_populates="topic", cascade="all, delete-orphan")


class KnowledgeChunk(Base):
    """Extracted content from PDF — one row per topic per week."""
    __tablename__ = "KnowledgeChunk"
    ChunkId   = Column(Integer, primary_key=True, index=True, autoincrement=True)
    SubjectId = Column(Integer)
    TopicId   = Column(Integer, ForeignKey("Topic.TopicId", ondelete="CASCADE"))
    TopicName = Column(String(300))
    Week      = Column(Integer, default=0)
    Content   = Column(Text)

    topic = relationship("Topic", back_populates="knowledge_chunks")


class Quiz(Base):
    """
    Each row = a pool of questions for one (Subject, Topic, Difficulty, Type) combo.
    UserId is NULL for admin-created pools.
    """
    __tablename__ = "Quiz"
    QuizId     = Column(Integer, primary_key=True, index=True, autoincrement=True)
    UserId     = Column(Integer, ForeignKey("Users.Id"), nullable=True)
    SubjectId  = Column(Integer)
    TopicName  = Column(String(300))
    Difficulty = Column(String(50))   # Easy | Medium | Hard
    QuizType   = Column(String(50))   # Conceptual | Numerical
    CreatedAt  = Column(DateTime, default=datetime.utcnow)

    questions = relationship("Question", back_populates="quiz", cascade="all, delete-orphan")
    attempts  = relationship("Attempt",  back_populates="quiz")


class Question(Base):
    __tablename__ = "Question"
    QuestionId    = Column(Integer, primary_key=True, index=True, autoincrement=True)
    QuizId        = Column(Integer, ForeignKey("Quiz.QuizId", ondelete="CASCADE"))
    QuestionText  = Column(Text)
    OptionA       = Column(String(500))
    OptionB       = Column(String(500))
    OptionC       = Column(String(500))
    OptionD       = Column(String(500))
    CorrectOption = Column(String(5))   # A | B | C | D
    Explanation   = Column(Text)

    quiz = relationship("Quiz", back_populates="questions")


class Attempt(Base):
    __tablename__ = "Attempt"
    AttemptId   = Column(Integer, primary_key=True, index=True, autoincrement=True)
    UserId      = Column(Integer, ForeignKey("Users.Id"))
    QuizId      = Column(Integer, ForeignKey("Quiz.QuizId"))
    Score       = Column(Integer)
    Total       = Column(Integer)
    Percentage  = Column(Float)
    AttemptedAt = Column(DateTime, default=datetime.utcnow)

    quiz    = relationship("Quiz",         back_populates="attempts")
    answers = relationship("AttemptAnswer", back_populates="attempt", cascade="all, delete-orphan")


class AttemptAnswer(Base):
    __tablename__ = "AttemptAnswer"
    AnswerId       = Column(Integer, primary_key=True, index=True, autoincrement=True)
    AttemptId      = Column(Integer, ForeignKey("Attempt.AttemptId", ondelete="CASCADE"))
    QuestionId     = Column(Integer)
    SelectedOption = Column(String(5))
    IsCorrect      = Column(Integer)   # 1 = correct, 0 = wrong

    attempt = relationship("Attempt", back_populates="answers")

class ExplainSession(Base):
    __tablename__ = "ExplainSession"
    ExplainId = Column(Integer, primary_key=True, index=True, autoincrement=True)
    UserId = Column(Integer, ForeignKey("Users.Id"))
    SubjectId = Column(Integer)
    TopicName = Column(String(300))
    Type = Column(String(50))
    CreatedAt = Column(DateTime, default=datetime.utcnow)