from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from database import get_db
from models import ExplainSession
from schemas import ExplainRequest
import cohere

router = APIRouter(prefix="/api/Explain", tags=["explain"])

import os

COHERE_API_KEY = os.getenv("COHERE_API_KEY")


def get_cohere_client() -> cohere.Client:
    return cohere.Client(COHERE_API_KEY)


@router.post("")
def get_explanation(request: ExplainRequest, db: Session = Depends(get_db)):
    # ── Content fetch ──────────────────────────────────────────────────────
    result = db.execute(text("""
        SELECT TOP 5 Content FROM KnowledgeChunk
        WHERE SubjectId = :subject_id
          AND TopicName = :topic_name
    """), {
        "subject_id": request.subjectId,
        "topic_name": request.topicName.strip(),
    })
    contents = [row[0] for row in result.fetchall() if row[0]]

    # LIKE fallback
    if not contents:
        result = db.execute(text("""
            SELECT TOP 5 Content FROM KnowledgeChunk
            WHERE SubjectId = :subject_id
              AND TopicName LIKE :topic_name
        """), {
            "subject_id": request.subjectId,
            "topic_name": f"%{request.topicName.strip()}%",
        })
        contents = [row[0] for row in result.fetchall() if row[0]]

    if not contents:
        raise HTTPException(
            status_code=404,
            detail=f"No lecture content found for topic: {request.topicName}"
        )

    combined = "\n\n---\n\n".join(contents)

    # ── Prompt — Conceptual vs Numerical ──────────────────────────────────
    if request.type == "Conceptual":
        type_instruction = """Focus on:
- What is this concept? (clear definition)
- Why is it important? (intuition, real-life analogy)
- Key properties and rules
- Common misconceptions to avoid
Do NOT use numerical calculations."""
    else:
        type_instruction = """Focus on:
- The formula and what each symbol means
- Step-by-step worked example with real numbers
- Another example with different numbers
- Common calculation mistakes to avoid
Include actual numbers and show full working."""

    prompt = f"""You are an expert university tutor explaining statistics and probability to a student.

Topic: {request.topicName}
Explanation Style: {request.type}

{type_instruction}

Lecture Content (use this as your source):
{combined[:5000]}

Write a clear, structured explanation. Use:
- Short paragraphs (easy to read on mobile)
- Numbered steps for procedures
- CRITICAL: Do NOT use LaTeX. No \\begin, \\end, \\bar, \\frac, \\sum, equations blocks
- Write ALL math in plain text ONLY:
    x-bar for mean, sqrt(x) for square root, x^2 for squared, a/b for fractions
    Use "x" for multiplication (NOT * or $1 or \times): 3 x 8 = 24
    Example formula: x-bar = (n1 x x1 + n2 x x2) / (n1 + n2)
    NEVER use * for multiplication — it breaks the output
- A friendly, encouraging tone

Do NOT include: professor name, course code, page numbers, LaTeX symbols, or metadata."""

    # ── Cohere call ────────────────────────────────────────────────────────
    try:
        co   = get_cohere_client()
        resp = co.chat(
            model      = "command-r-08-2024",
            message    = prompt,
            max_tokens = 2000,
            temperature= 0.4,
        )
        explanation = resp.text.strip()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI error: {str(e)}")

    # ── Save session ───────────────────────────────────────────────────────
    session = ExplainSession(
        UserId    = request.userId,
        SubjectId = request.subjectId,
        TopicName = request.topicName,
        Type      = request.type,
    )
    db.add(session)
    db.commit()

    return {
        "topicName":   request.topicName,
        "type":        request.type,
        "explanation": explanation,
    }