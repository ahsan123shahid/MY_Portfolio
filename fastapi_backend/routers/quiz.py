from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from database import get_db
from models import Quiz, Question, Attempt, AttemptAnswer
from schemas import (
    QuizGenerateRequest, QuizSubmitRequest,
    QuizQuestionItem, QuestionResult,
)
import random

router = APIRouter(prefix="/api/Quiz", tags=["quiz"])


# ════════════════════════════════════════════════════════════════════════════
# GENERATE — DB se filter kar ke random questions do
# ════════════════════════════════════════════════════════════════════════════

@router.post("/generate")
def generate_quiz(request: QuizGenerateRequest, db: Session = Depends(get_db)):
    """
    DB mein pehle se admin ke generate kiye questions hain (Quiz + Question tables).
    Student ke request ke mutabiq filter karo:
      - TopicName  (exact match)
      - Difficulty (Easy / Medium / Hard)
      - QuizType   (Conceptual / Numerical)
    Phir random sample karo questionCount tak.
    """
    print(f"\n[QUIZ] topic='{request.topicName}' diff={request.difficulty} "
          f"type={request.quizType} count={request.questionCount}")

    topic = request.topicName.strip()

    # ── Step 1: Matching Quiz rows dhundo ──────────────────────────────────
    # Admin ne pdf.py se jo quizzes banaye woh Quiz table mein hain
    # Har Quiz row: SubjectId, TopicName, Difficulty, QuizType
    matching_quizzes = db.query(Quiz).filter(
        Quiz.SubjectId  == request.subjectId,
        Quiz.TopicName  == topic,
        Quiz.Difficulty == request.difficulty,
        Quiz.QuizType   == request.quizType,
        ).all()

    print(f"[QUIZ] Matching quizzes: {len(matching_quizzes)}")

    # ── Step 2: Un quizzes ke saare questions nikalo ───────────────────────
    pool: list = []
    for quiz in matching_quizzes:
        questions = db.query(Question).filter(
            Question.QuizId == quiz.QuizId
        ).all()
        for q in questions:
            pool.append({
                "question_id":   q.QuestionId,
                "question_text": q.QuestionText,
                "option_a":      q.OptionA,
                "option_b":      q.OptionB,
                "option_c":      q.OptionC,
                "option_d":      q.OptionD,
                "correct_option": q.CorrectOption,
                "explanation":   q.Explanation or "",
            })

    print(f"[QUIZ] Questions in pool: {len(pool)}")

    # ── Step 3: Pool khaali hai? ───────────────────────────────────────────
    if not pool:
        # Try: same topic + difficulty, any type (fallback)
        fallback_quizzes = db.query(Quiz).filter(
            Quiz.SubjectId  == request.subjectId,
            Quiz.TopicName  == topic,
            Quiz.Difficulty == request.difficulty,
            ).all()

        for quiz in fallback_quizzes:
            questions = db.query(Question).filter(
                Question.QuizId == quiz.QuizId
            ).all()
            for q in questions:
                pool.append({
                    "question_id":    q.QuestionId,
                    "question_text":  q.QuestionText,
                    "option_a":       q.OptionA,
                    "option_b":       q.OptionB,
                    "option_c":       q.OptionC,
                    "option_d":       q.OptionD,
                    "correct_option": q.CorrectOption,
                    "explanation":    q.Explanation or "",
                })

        if pool:
            print(f"[QUIZ] Fallback (any type): {len(pool)} questions")
        else:
            # Last resort: same topic, any difficulty or type
            all_quizzes = db.query(Quiz).filter(
                Quiz.SubjectId == request.subjectId,
                Quiz.TopicName == topic,
                ).all()
            for quiz in all_quizzes:
                questions = db.query(Question).filter(
                    Question.QuizId == quiz.QuizId
                ).all()
                for q in questions:
                    pool.append({
                        "question_id":    q.QuestionId,
                        "question_text":  q.QuestionText,
                        "option_a":       q.OptionA,
                        "option_b":       q.OptionB,
                        "option_c":       q.OptionC,
                        "option_d":       q.OptionD,
                        "correct_option": q.CorrectOption,
                        "explanation":    q.Explanation or "",
                    })
            if pool:
                print(f"[QUIZ] Fallback (any diff+type): {len(pool)} questions")

    if not pool:
        raise HTTPException(
            status_code=404,
            detail=f"No questions found for topic '{topic}'. "
                   f"Please ask admin to upload PDF for this subject."
        )

    # ── Step 4: Smart Random — recently seen questions hatao ──────────────
    count = min(request.questionCount, len(pool))

    # Is user ne is topic pe pichle 3 attempts mein kaunse questions dekhe?
    recent_attempts = db.execute(text("""
        SELECT TOP 3 a.QuizId
        FROM Attempt a
        JOIN Quiz q ON a.QuizId = q.QuizId
        WHERE a.UserId     = :user_id
          AND q.TopicName  = :topic
          AND q.Difficulty = :diff
          AND q.QuizType   = :qtype
        ORDER BY a.AttemptedAt DESC
    """), {
        "user_id": request.userId,
        "topic":   topic,
        "diff":    request.difficulty,
        "qtype":   request.quizType,
    }).fetchall()

    # Recently seen question texts nikalo
    recently_seen_texts = set()
    for row in recent_attempts:
        recent_qs = db.query(Question).filter(Question.QuizId == row[0]).all()
        for rq in recent_qs:
            recently_seen_texts.add(rq.QuestionText.strip().lower())

    # Pool split: fresh vs seen
    fresh_pool = [q for q in pool if q["question_text"].strip().lower() not in recently_seen_texts]
    seen_pool  = [q for q in pool if q["question_text"].strip().lower() in recently_seen_texts]

    print(f"[QUIZ] Pool: {len(pool)} total | {len(fresh_pool)} fresh | {len(seen_pool)} seen")

    random.shuffle(fresh_pool)
    random.shuffle(seen_pool)

    if len(fresh_pool) >= count:
        selected = fresh_pool[:count]
        print(f"[QUIZ] All {count} from fresh pool")
    else:
        needed = count - len(fresh_pool)
        selected = fresh_pool + seen_pool[:needed]
        random.shuffle(selected)
        print(f"[QUIZ] {len(fresh_pool)} fresh + {needed} seen = {len(selected)}")

    # ── Step 5: Quiz record banao (attempt ke liye) ────────────────────────
    quiz_record = Quiz(
        UserId    = request.userId,
        SubjectId = request.subjectId,
        TopicName = topic,
        Difficulty= request.difficulty,
        QuizType  = request.quizType,
    )
    db.add(quiz_record)
    db.commit()
    db.refresh(quiz_record)

    # Selected questions ko is quiz se link karo
    saved_question_ids = []
    for q in selected:
        new_q = Question(
            QuizId        = quiz_record.QuizId,
            QuestionText  = q["question_text"],
            OptionA       = q["option_a"],
            OptionB       = q["option_b"],
            OptionC       = q["option_c"],
            OptionD       = q["option_d"],
            CorrectOption = q["correct_option"],
            Explanation   = q["explanation"],
        )
        db.add(new_q)
        db.commit()
        db.refresh(new_q)
        saved_question_ids.append(new_q.QuestionId)

    # ── Step 6: Response ───────────────────────────────────────────────────
    # Questions phir se fetch karo (saved IDs se) — correct IDs ke saath
    final_questions = db.query(Question).filter(
        Question.QuizId == quiz_record.QuizId
    ).all()

    return {
        "success":    True,
        "quizId":     quiz_record.QuizId,
        "topicName":  topic,
        "difficulty": request.difficulty,
        "quizType":   request.quizType,
        "questions": [
            {
                "questionId":   q.QuestionId,
                "questionText": q.QuestionText,
                "optionA":      q.OptionA,
                "optionB":      q.OptionB,
                "optionC":      q.OptionC,
                "optionD":      q.OptionD,
            }
            for q in final_questions
        ],
    }


# ════════════════════════════════════════════════════════════════════════════
# SUBMIT — answers check karo, attempt save karo
# ════════════════════════════════════════════════════════════════════════════

@router.post("/submit")
def submit_quiz(request: QuizSubmitRequest, db: Session = Depends(get_db)):
    questions     = db.query(Question).filter(Question.QuizId == request.quizId).all()
    question_dict = {q.QuestionId: q for q in questions}

    score   = 0
    results = []

    for answer in request.answers:
        q = question_dict.get(answer.questionId)
        if not q:
            continue

        is_correct = q.CorrectOption.upper() == answer.selectedOption.upper()
        if is_correct:
            score += 1

        results.append({
            "questionId":     q.QuestionId,
            "questionText":   q.QuestionText,
            "optionA":        q.OptionA,
            "optionB":        q.OptionB,
            "optionC":        q.OptionC,
            "optionD":        q.OptionD,
            "selectedOption": answer.selectedOption,
            "correctOption":  q.CorrectOption,
            "explanation":    q.Explanation or "",
            "isCorrect":      is_correct,
        })

    total      = len(results)
    percentage = round((score / total * 100), 2) if total > 0 else 0.0

    attempt = Attempt(
        UserId     = request.userId,
        QuizId     = request.quizId,
        Score      = score,
        Total      = total,
        Percentage = percentage,
    )
    db.add(attempt)
    db.commit()

    return {
        "score":      score,
        "total":      total,
        "percentage": percentage,
        "results":    results,
    }


# ════════════════════════════════════════════════════════════════════════════
# HISTORY — user ki past attempts
# ════════════════════════════════════════════════════════════════════════════

@router.get("/history/{user_id}")
def get_history(user_id: int, db: Session = Depends(get_db)):
    result = db.execute(text("""
        SELECT a.AttemptId, a.Score, a.Total, a.Percentage, a.AttemptedAt,
               q.TopicName, q.Difficulty, q.QuizType
        FROM Attempt a
        JOIN Quiz q ON a.QuizId = q.QuizId
        WHERE a.UserId = :user_id
        ORDER BY a.AttemptedAt DESC
    """), {"user_id": user_id})

    return [
        {
            "attemptId":  row[0],
            "score":      row[1],
            "total":      row[2],
            "percentage": row[3],
            "date":       row[4].strftime("%Y-%m-%d") if row[4] else "",
            "topicName":  row[5],
            "difficulty": row[6],
            "quizType":   row[7],
        }
        for row in result.fetchall()
    ]


# ════════════════════════════════════════════════════════════════════════════
# AVAILABLE OPTIONS — Flutter ko batao kaunse topics/difficulties available hain
# ════════════════════════════════════════════════════════════════════════════

@router.get("/available-options/{subject_id}")
def get_available_options(subject_id: int, db: Session = Depends(get_db)):
    """
    Flutter is endpoint se check kare ke kaunsi combinations available hain.
    Dropdown mein sirf wahi show hogi jo DB mein exist karti hain.
    """
    quizzes = db.query(Quiz).filter(
        Quiz.SubjectId == subject_id,
        Quiz.UserId    == None,          # Admin ke generate kiye (no userId)
    ).all()

    topics      = sorted(set(q.TopicName  for q in quizzes if q.TopicName))
    difficulties = sorted(set(q.Difficulty for q in quizzes if q.Difficulty))
    types        = sorted(set(q.QuizType   for q in quizzes if q.QuizType))

    # Topic ke liye question count bhi do
    topic_counts = {}
    for topic in topics:
        count = 0
        for quiz in db.query(Quiz).filter(
                Quiz.SubjectId == subject_id,
                Quiz.TopicName == topic,
                Quiz.UserId    == None,
        ).all():
            count += db.query(Question).filter(
                Question.QuizId == quiz.QuizId
            ).count()
        topic_counts[topic] = count

    return {
        "subjectId":    subject_id,
        "topics":       [{"name": t, "questionCount": topic_counts.get(t, 0)} for t in topics],
        "difficulties": difficulties,
        "types":        types,
    }