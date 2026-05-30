from pydantic import BaseModel
from typing import List, Optional

class LoginRequest(BaseModel):
    email: str
    password: str

class SignupRequest(BaseModel):
    name: str
    email: str
    password: str

class UserResponse(BaseModel):
    Id: int
    Name: str
    Email: str
    class Config:
        from_attributes = True

class SubjectResponse(BaseModel):
    SubjectId: int
    Name: str
    class Config:
        from_attributes = True

class TopicResponse(BaseModel):
    TopicId: int
    TopicName: str
    class Config:
        from_attributes = True

class NoteChunkResponse(BaseModel):
    ChunkId: int
    Content: str
    Difficulty: Optional[str] = ""
    Type: Optional[str] = ""
    Week: Optional[int] = 0
    class Config:
        from_attributes = True

class QuizGenerateRequest(BaseModel):
    userId: int
    subjectId: int
    topicName: str
    difficulty: str
    quizType: str
    questionCount: int

class MCQuestion(BaseModel):
    question_text: str
    option_a: str
    option_b: str
    option_c: str
    option_d: str
    correct_option: str
    explanation: str

class QuizQuestionItem(BaseModel):
    questionId: int
    questionText: str
    optionA: str
    optionB: str
    optionC: str
    optionD: str

class QuizResponse(BaseModel):
    quizId: int
    topicName: str
    difficulty: str
    questions: List[QuizQuestionItem]

class AnswerItem(BaseModel):
    questionId: int
    selectedOption: str

class QuizSubmitRequest(BaseModel):
    userId: int
    quizId: int
    answers: List[AnswerItem]

class QuestionResult(BaseModel):
    questionId: int
    questionText: str
    optionA: str
    optionB: str
    optionC: str
    optionD: str
    selectedOption: str
    correctOption: str
    explanation: str
    isCorrect: bool

class SubmitResult(BaseModel):
    score: int
    total: int
    percentage: float
    results: List[QuestionResult]

class HistoryItem(BaseModel):
    attemptId: int
    topicName: str
    difficulty: str
    score: int
    total: int
    percentage: float
    date: str

class ExplainRequest(BaseModel):
    userId: int
    subjectId: int
    topicName: str
    type: str

class ExplainResponse(BaseModel):
    topicName: str
    type: str
    explanation: str

class ApiResponse(BaseModel):
    success: bool
    message: str = ""
    data: Optional[dict] = None