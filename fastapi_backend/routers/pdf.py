"""
pdf.py — Admin PDF Processing Router
======================================
Content Extraction Strategy:
  - ZERO AI calls for content extraction
  - Pure regex + fuzzy heading-match (space-collapse technique)
  - Handles PDF broken words: 'Simple B ar Cha rt' → matches 'Simple Bar Chart'
  - "Examples of X" topics: if no separate heading found, uses parent X content
  - Single-word headings supported (e.g. 'Tabulation')
  - Generic headings (Example, Solution, So,) filtered out
  - Unmatched topics fall back to 'Introduction' section, then PDF start
  - AI (Cohere) used ONLY for question generation — runs in background

Pipeline:
  [1] PDF → raw text (PyPDF2)
  [2] Regex → topic list from Objectives section
  [3] Heading-match → content per topic  (NO AI)
  [4] Cohere → 60 MCQs per topic  (background task, Flutter never times out)
"""

import io
import re
import json
import urllib.parse

import cohere
import PyPDF2 as pdf2
from fastapi import APIRouter, BackgroundTasks, Depends, File, HTTPException, UploadFile
from sqlalchemy.orm import Session

from database import get_db
from models import KnowledgeChunk, Question, Quiz, Topic

router = APIRouter(prefix="/api/admin", tags=["admin-pdf"])

import os

COHERE_API_KEY = os.getenv("COHERE_API_KEY")


def get_cohere_client() -> cohere.Client:
    return cohere.Client(COHERE_API_KEY)


# ════════════════════════════════════════════════════════════════════════════
# STEP 1 — PDF → RAW TEXT
# ════════════════════════════════════════════════════════════════════════════

def extract_raw_text(pdf_bytes: bytes) -> str:
    reader = pdf2.PdfReader(io.BytesIO(pdf_bytes))
    pages = []
    for page in reader.pages:
        t = page.extract_text()
        if t:
            pages.append(t)
    return "\n".join(pages)


# ════════════════════════════════════════════════════════════════════════════
# STEP 2 — WEEK DETECTION
# ════════════════════════════════════════════════════════════════════════════

def detect_week(filename: str, text: str) -> int:
    for pattern in [r'[Ww][Ee][Ee][Kk][-_\s]*(\d+)', r'[-_](\d+)']:
        m = re.search(pattern, filename)
        if m:
            return int(m.group(1))
    for pattern in [r'\(Week\s*(\d+)\)', r'[Ww]eek\s*[-]?\s*(\d+)']:
        m = re.search(pattern, text[:500])
        if m:
            return int(m.group(1))
    return 1


# ════════════════════════════════════════════════════════════════════════════
# STEP 3 — REGEX TOPIC EXTRACTION (from Objectives section)
# ════════════════════════════════════════════════════════════════════════════

def extract_topics_regex(text: str) -> list:
    obj_match = re.search(
        r'objectives?\s*[:\-]?\s*(.*?)(?=\n[A-Z][a-z].*\n|introduction\s*[:\n]|$)',
        text,
        re.IGNORECASE | re.DOTALL,
        )
    if not obj_match:
        return []

    section = obj_match.group(1)
    lines = re.split(r'[\n\r•\uf0b7\uf0d8]|\d+[\.\)]\s', section)

    garbage = [
        'email', 'whatsapp', 'lecture', 'university', 'department',
        'mr.', 'dr.', 'ms.', 'statistics and', 'stt-', 'stt -',
        'learning objectives', 'objectives',
    ]
    sentence_starters = [
        'the ', 'a ', 'an ', 'in ', 'if ', 'when ', 'since ', 'so,',
        'and ', 'but ', 'we ', 'let ', 'given ', 'this ', 'that ',
        'is ', 'are ', 'it ', 'for ',
    ]

    topics = []
    consecutive_bad = 0

    for line in lines:
        line = re.sub(r'^[\d\.\)\-\*\•\s\uf0b7\uf0d8]+', '', line).strip()
        line = re.sub(r'\s+', ' ', line)
        if not line:
            continue
        if any(line.lower().startswith(s) for s in sentence_starters):
            consecutive_bad += 1
            if consecutive_bad >= 2:
                break
            continue
        if len(line) < 3 or len(line) > 70:
            continue
        if len(line.split()) > 8:
            consecutive_bad += 1
            if consecutive_bad >= 2:
                break
            continue
        if not re.match(r'^[A-Z]', line):
            consecutive_bad += 1
            if consecutive_bad >= 2:
                break
            continue
        if any(g in line.lower() for g in garbage):
            continue
        if re.search(r'[,;]$', line):
            continue
        consecutive_bad = 0
        topics.append(line)

    seen, unique = set(), []
    for t in topics:
        if t.lower() not in seen:
            seen.add(t.lower())
            unique.append(t)

    return unique[:12]


# ════════════════════════════════════════════════════════════════════════════
# STEP 4 — HEADING-BASED CONTENT EXTRACTION  (NO AI)
#
# space-collapse fuzzy match:
#   PDF broken words: 'Simple B ar Cha rt' → collapse → 'simplebarchart'
#   Topic name:       'Simple Bar Chart'   → collapse → 'simplebarchart'  ✅
#
# "Examples of X" handling:
#   Many PDFs don't have a separate heading for "Examples of X".
#   Fix: if no heading found for "Examples of X", use parent "X" content.
#
# Generic heading filter:
#   Words like "Example", "Solution", "So," are NOT topic headings.
#   They are filtered out before matching.
# ════════════════════════════════════════════════════════════════════════════

_NOISE_PATTERNS = [
    r'statistics and probability',
    r'mr\.\s*\w+',
    r'email\s*id',
    r'whatsapp',
    r'stt-\d+',
    r'@\w+\.edu',
    r'^\s*\d+\s*$',
]

# Single words/phrases that appear as lines in PDFs but are NOT topic headings
_GENERIC_HEADINGS = {
    'example', 'examples', 'solution', 'solutions', 'so,', 'so', 'and',
    'also,', 'also', 'now,', 'now', 'hence', 'since', 'as', 'or', 'than',
    'note', 'proof', 'given', 'where', 'here', 'thus', 'therefore', 'items',
    'or', 'but', 'let', 'then', 'thus,', 'therefore,', 'hence,',
}


def _is_noise(line: str) -> bool:
    l = line.lower().strip()
    if not l:
        return True
    return any(re.search(p, l) for p in _NOISE_PATTERNS)


def _is_heading(line: str) -> bool:
    s = re.sub(r'\s+', ' ', line.strip())
    if not s or _is_noise(s):
        return False
    if re.match(r'^[•\uf0b7\uf0d8\-\*\d]', s):
        return False
    words = s.split()
    if not (1 <= len(words) <= 10):
        return False
    if not re.match(r'^[A-Z]', s):
        return False
    if len(s) > 80:
        return False

    # Filter generic single-word/phrase headings
    if s.lower().strip().rstrip('.,:') in _GENERIC_HEADINGS:
        return False

    _SENT_STARTS = (
        'the ', 'a ', 'an ', 'in ', 'if ', 'when ', 'since ', 'and ',
        'but ', 'we ', 'this ', 'that ', 'is ', 'are ', 'it ', 'for ',
        'suppose ', 'both ', 'on ', 'by ', 'while ', 'such ', 'data ',
        'as ', 'so ', 'to ', 'or ', 'let ', 'now', 'also', 'hence',
        'where', 'here', 'thus', 'given', 'than', 'what', 'note',
    )
    if s.lower().startswith(_SENT_STARTS):
        return False

    if re.search(r'\d{4,}', s):
        return False

    return True


def _space_collapse(text: str) -> str:
    return re.sub(r'\s+', '', text).lower()


def _match_score(heading: str, topic: str) -> float:
    h = _space_collapse(heading)
    t = _space_collapse(topic)

    if h == t:
        return 100
    if t in h or h in t:
        return 85

    # Word-level overlap — exclude stop words + 'examples'
    _STOP = {'of', 'and', 'the', 'a', 'an', 'in', 'for', 'to', 'is',
             'are', 'it', 'examples', 'example'}
    topic_words = [w for w in topic.lower().split() if w not in _STOP and len(w) > 2]
    if not topic_words:
        return 0

    heading_tokens = [_space_collapse(tok) for tok in heading.split()]
    matched = sum(1 for tw in topic_words if tw in heading_tokens)
    return (matched / len(topic_words)) * 70


def _parent_topic(topic: str) -> str:
    """
    'Examples of Conditional Probability' → 'Conditional Probability'
    'Examples of Bayes' Theorem'           → "Bayes' Theorem"
    Returns "" if not an "Examples of" topic.
    """
    m = re.match(r'^examples?\s+of\s+(.+)$', topic, re.IGNORECASE)
    return m.group(1).strip() if m else ""


def extract_content_by_headings(pdf_text: str, topics: list) -> dict:
    """
    Returns {topic_name: content} for all topics. No AI calls.
    """
    lines = pdf_text.split('\n')

    # Build heading index
    heading_positions: list = []
    for i, line in enumerate(lines):
        if _is_heading(line):
            clean = re.sub(r'\s+', ' ', line.strip())
            heading_positions.append((i, clean))

    print(f"  [HEADINGS] {len(heading_positions)} headings detected")
    for _, h in heading_positions:
        print(f"    → '{h}'")

    # Find Introduction section (fallback)
    intro_content = ""
    for (h_idx, h_name) in heading_positions:
        if _space_collapse(h_name) == 'introduction':
            next_h = next((idx for (idx, _) in heading_positions if idx > h_idx), len(lines))
            intro_lines = [
                lines[i].strip() for i in range(h_idx, next_h)
                if lines[i].strip() and not _is_noise(lines[i])
            ]
            intro_content = '\n'.join(intro_lines)
            break

    _THRESHOLD = 60
    result: dict = {}

    for topic in topics:
        best_idx   = None
        best_score = 0.0
        best_name  = ""

        for (line_idx, heading) in heading_positions:
            score = _match_score(heading, topic)
            if score > best_score and score >= _THRESHOLD:
                best_score = score
                best_idx   = line_idx
                best_name  = heading

        # ── Matched heading found ────────────────────────────────────
        if best_idx is not None:
            next_h_line = next(
                (idx for (idx, _) in heading_positions if idx > best_idx),
                len(lines)
            )
            content_lines = [
                lines[i].strip()
                for i in range(best_idx, next_h_line)
                if lines[i].strip() and not _is_noise(lines[i])
            ]
            content = '\n'.join(content_lines).strip()

            if len(content) >= 80:
                print(f"  [MATCHED]  '{topic}' → '{best_name}' (score={best_score:.0f}, {len(content)} chars)")
                result[topic] = content
                continue

        # ── "Examples of X" fallback: use parent topic content ───────
        parent = _parent_topic(topic)
        if parent and parent in result and len(result[parent]) >= 80:
            print(f"  [PARENT]   '{topic}' → using parent '{parent}' content ({len(result[parent])} chars)")
            result[topic] = result[parent]
            continue

        # ── Introduction section fallback ────────────────────────────
        if intro_content and len(intro_content) >= 80:
            print(f"  [INTRO]    '{topic}' — using Introduction section")
            result[topic] = f"Topic: {topic}\n\n{intro_content}"
            continue

        # ── PDF start fallback ───────────────────────────────────────
        print(f"  [PDF-START] '{topic}' — using PDF start text")
        result[topic] = f"Topic: {topic}\n\n{pdf_text[:3000]}"

    return result


# ════════════════════════════════════════════════════════════════════════════
# COHERE HELPERS  (used ONLY for question generation)
# ════════════════════════════════════════════════════════════════════════════

def cohere_chat(co: cohere.Client, prompt: str, max_tokens: int = 4000) -> str:
    resp = co.chat(
        model="command-r-08-2024",
        message=prompt,
        max_tokens=min(max_tokens, 4096),
        temperature=0.3,
    )
    return resp.text.strip()


def robust_json_parse(raw: str):
    clean = re.sub(r'^```(?:json)?\s*', '', raw, flags=re.MULTILINE)
    clean = re.sub(r'\s*```\s*$',       '', clean, flags=re.MULTILINE).strip()

    for attempt in (clean, raw):
        try:
            return json.loads(attempt)
        except json.JSONDecodeError:
            pass

    for open_c, close_c in [('{', '}'), ('[', ']')]:
        start = clean.find(open_c)
        end   = clean.rfind(close_c) + 1
        if start != -1 and end > start:
            try:
                return json.loads(clean[start:end])
            except json.JSONDecodeError:
                pass

    fixed = re.sub(r',\s*([}\]])', r'\1', clean)
    fixed = re.sub(r"(?<![\\])'",  '"',   fixed)
    try:
        return json.loads(fixed)
    except json.JSONDecodeError:
        pass

    import ast
    try:
        return ast.literal_eval(clean)
    except Exception:
        pass

    raise ValueError(f"Cannot parse JSON:\n{clean[:400]}")


# ════════════════════════════════════════════════════════════════════════════
# STEP 5 — QUESTION GENERATION  (background, 6 calls per topic)
# ════════════════════════════════════════════════════════════════════════════

_QUESTION_CONFIGS = [
    ("Easy",   "Conceptual", 10),
    ("Easy",   "Numerical",  10),
    ("Medium", "Conceptual", 10),
    ("Medium", "Numerical",  10),
    ("Hard",   "Conceptual", 10),
    ("Hard",   "Numerical",  10),
]


def ai_generate_questions(co: cohere.Client, topic_name: str, content: str) -> list:
    all_questions = []

    for difficulty, qtype, count in _QUESTION_CONFIGS:
        type_note = (
            "Test understanding of definitions, properties, and theorems. No calculation required."
            if qtype == "Conceptual"
            else "Test ability to apply formulas with actual numbers. Include specific values."
        )

        prompt = f"""You are a university professor creating a {difficulty}-level {qtype} quiz.

Topic: {topic_name}
{type_note}

Topic Content:
{content[:4000]}

Generate exactly {count} multiple-choice questions.

Rules:
- 4 options per question (A, B, C, D), exactly one correct.
- Easy: direct recall or one-step problems.
- Medium: two-to-three step reasoning or moderate calculation.
- Hard: multi-step, tricky concepts, or complex calculation.
- Numerical questions must contain actual numbers.
- Explanation must clearly justify the correct answer.
- No duplicate questions.

Return ONLY a valid JSON array (no preamble, no markdown):
[
  {{
    "question": "...",
    "option_a": "...",
    "option_b": "...",
    "option_c": "...",
    "option_d": "...",
    "correct": "A",
    "explanation": "..."
  }}
]"""

        try:
            raw = cohere_chat(co, prompt, max_tokens=4000)
            qs  = robust_json_parse(raw)
            if not isinstance(qs, list):
                print(f"  [SKIP] {difficulty}/{qtype}: not a list")
                continue
            for q in qs[:count]:
                q["difficulty"] = difficulty
                q["type"]       = qtype
                all_questions.append(q)
            print(f"  [OK] {difficulty}/{qtype}: {len(qs[:count])} Qs")
        except Exception as e:
            print(f"  [ERR] {difficulty}/{qtype}: {e}")

    return all_questions


# ════════════════════════════════════════════════════════════════════════════
# DB HELPERS
# ════════════════════════════════════════════════════════════════════════════

def _save_topic(db: Session, subject_id: int, topic_name: str) -> int:
    existing = db.query(Topic).filter(
        Topic.SubjectId == subject_id,
        Topic.TopicName == topic_name,
        ).first()
    if existing:
        return existing.TopicId
    t = Topic(SubjectId=subject_id, TopicName=topic_name)
    db.add(t)
    db.commit()
    db.refresh(t)
    return t.TopicId


def _save_chunk(db: Session, subject_id: int, topic_id: int,
                topic_name: str, week: int, content: str):
    exists = db.query(KnowledgeChunk).filter(
        KnowledgeChunk.SubjectId == subject_id,
        KnowledgeChunk.TopicName == topic_name,
        KnowledgeChunk.Week      == week,
        ).first()
    if not exists:
        c = KnowledgeChunk(
            SubjectId=subject_id,
            TopicId=topic_id,
            TopicName=topic_name,
            Week=week,
            Content=content,
        )
        db.add(c)
        db.commit()


def _save_questions(db: Session, subject_id: int, topic_name: str, questions: list) -> int:
    quiz_map: dict = {}
    saved = 0

    for q in questions:
        diff  = q.get("difficulty", "Medium")
        qtype = q.get("type", "Conceptual")
        key   = (diff, qtype)

        if key not in quiz_map:
            existing = db.query(Quiz).filter(
                Quiz.SubjectId  == subject_id,
                Quiz.TopicName  == topic_name,
                Quiz.Difficulty == diff,
                Quiz.QuizType   == qtype,
                ).first()
            if existing:
                quiz_map[key] = existing.QuizId
            else:
                nq = Quiz(SubjectId=subject_id, TopicName=topic_name,
                          Difficulty=diff, QuizType=qtype)
                db.add(nq)
                db.commit()
                db.refresh(nq)
                quiz_map[key] = nq.QuizId

        question = Question(
            QuizId        = quiz_map[key],
            QuestionText  = q.get("question",    ""),
            OptionA       = q.get("option_a",    ""),
            OptionB       = q.get("option_b",    ""),
            OptionC       = q.get("option_c",    ""),
            OptionD       = q.get("option_d",    ""),
            CorrectOption = q.get("correct",     "A"),
            Explanation   = q.get("explanation", ""),
        )
        db.add(question)
        saved += 1

    db.commit()
    return saved


# ════════════════════════════════════════════════════════════════════════════
# BACKGROUND TASK
# ════════════════════════════════════════════════════════════════════════════

def _background_generate_all_questions(subject_id: int, saved_data: list):
    """Runs AFTER HTTP response — Flutter never times out."""
    from database import SessionLocal
    db = SessionLocal()
    co = get_cohere_client()

    try:
        print(f"\n[BG] Starting for {len(saved_data)} topics...")
        total = 0
        for item in saved_data:
            print(f"\n[BG] Topic: '{item['topic_name']}'")
            qs = ai_generate_questions(co, item["topic_name"], item["topic_content"])
            if qs:
                n = _save_questions(db, subject_id, item["topic_name"], qs)
                total += n
                print(f"[BG] → {n} questions saved")
        print(f"\n[BG] DONE: {total} total questions saved.")
    except Exception as e:
        import traceback
        print(f"[BG] ERROR: {e}")
        traceback.print_exc()
    finally:
        db.close()


# ════════════════════════════════════════════════════════════════════════════
# ENDPOINTS
# ════════════════════════════════════════════════════════════════════════════

@router.post("/upload-pdf")
async def upload_pdf(
        subject_id: int,
        background_tasks: BackgroundTasks,
        file: UploadFile = File(...),
        db: Session = Depends(get_db),
):
    if not file.filename.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Only PDF files are supported.")

    try:
        raw_bytes = await file.read()
        pdf_text  = extract_raw_text(raw_bytes)

        if len(pdf_text.strip()) < 100:
            raise HTTPException(status_code=400,
                                detail="PDF appears empty or is scanned. Please upload a text-based PDF.")

        week = detect_week(file.filename, pdf_text)

        print(f"\n{'='*60}")
        print(f"FILE : {file.filename}  |  WEEK: {week}  |  CHARS: {len(pdf_text)}")
        print(f"{'='*60}")

        # [1/3] Topics via regex
        print("\n[1/3] Topics (regex)...")
        topics = extract_topics_regex(pdf_text)
        print(f"      {topics}")

        if not topics:
            raise HTTPException(status_code=400,
                                detail="No topics found in Objectives section.")

        # [2/3] Content via heading-match (no AI)
        print("\n[2/3] Content (heading-match)...")
        topic_contents = extract_content_by_headings(pdf_text, topics)

        saved_data = []
        for topic_name in topics:
            content = topic_contents.get(topic_name, "").strip()
            if not content or len(content) < 50:
                content = f"Topic: {topic_name}\n\n{pdf_text[:3000]}"
                print(f"  [FALLBACK] '{topic_name}'")
            else:
                print(f"  ✔ '{topic_name}' ({len(content)} chars)")

            t_id = _save_topic(db, subject_id, topic_name)
            _save_chunk(db, subject_id, t_id, topic_name, week, content)
            saved_data.append({"topic_name": topic_name, "topic_content": content})

        # [3/3] Questions in background
        print("\n[3/3] Scheduling question generation (background)...")
        background_tasks.add_task(_background_generate_all_questions, subject_id, saved_data)

        return {
            "success":             True,
            "filename":            file.filename,
            "weekDetected":        week,
            "topicsExtracted":     [d["topic_name"] for d in saved_data],
            "topicsSaved":         len(saved_data),
            "questionsSaved":      0,
            "questionsGenerating": True,
            "message":             f"{len(saved_data)} topics saved. Questions generating in background.",
        }

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        import traceback; traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Unexpected error: {e}")


@router.get("/generation-status/{subject_id}")
def get_generation_status(subject_id: int, db: Session = Depends(get_db)):
    chunks      = db.query(KnowledgeChunk).filter(KnowledgeChunk.SubjectId == subject_id).all()
    topic_names = list({c.TopicName for c in chunks if c.TopicName})
    status = []

    for topic_name in topic_names:
        quizzes = db.query(Quiz).filter(
            Quiz.SubjectId == subject_id, Quiz.TopicName == topic_name).all()
        q_count = sum(
            db.query(Question).filter(Question.QuizId == q.QuizId).count()
            for q in quizzes)
        status.append({"topicName": topic_name, "questionCount": q_count, "ready": q_count > 0})

    total   = sum(s["questionCount"] for s in status)
    all_rdy = all(s["ready"] for s in status) if status else False
    return {"subjectId": subject_id, "topics": status, "totalQuestions": total, "allReady": all_rdy}


@router.post("/regenerate-questions/{subject_id}")
def regenerate_questions(subject_id: int, background_tasks: BackgroundTasks,
                         db: Session = Depends(get_db)):
    chunks = db.query(KnowledgeChunk).filter(KnowledgeChunk.SubjectId == subject_id).all()
    if not chunks:
        raise HTTPException(status_code=400, detail="No knowledge chunks found.")

    topic_map: dict = {}
    for c in chunks:
        if c.TopicName:
            topic_map.setdefault(c.TopicName, "")
            topic_map[c.TopicName] += (c.Content or "") + "\n\n"

    saved_data = [{"topic_name": k, "topic_content": v[:5000]} for k, v in topic_map.items()]
    background_tasks.add_task(_background_generate_all_questions, subject_id, saved_data)

    return {"success": True, "topicsScheduled": len(saved_data),
            "message": f"Regeneration started for {len(saved_data)} topics."}


@router.post("/generate-questions-for-topic/{subject_id}")
def generate_questions_for_topic(subject_id: int, topic_name: str,
                                 background_tasks: BackgroundTasks,
                                 db: Session = Depends(get_db)):
    chunks = db.query(KnowledgeChunk).filter(
        KnowledgeChunk.SubjectId == subject_id,
        KnowledgeChunk.TopicName == topic_name).all()
    if not chunks:
        raise HTTPException(status_code=404, detail=f"No content for '{topic_name}'.")

    content = "\n\n".join(c.Content for c in chunks if c.Content).strip()
    if len(content) < 50:
        raise HTTPException(status_code=400, detail=f"Content too short for '{topic_name}'.")

    for quiz in db.query(Quiz).filter(
            Quiz.SubjectId == subject_id, Quiz.TopicName == topic_name).all():
        db.query(Question).filter(Question.QuizId == quiz.QuizId).delete()
    db.commit()

    background_tasks.add_task(_background_generate_all_questions, subject_id,
                              [{"topic_name": topic_name, "topic_content": content}])
    return {"success": True, "topicName": topic_name,
            "message": f"Generation started for '{topic_name}'."}


@router.get("/knowledge-chunks/{subject_id}")
def get_knowledge_chunks(subject_id: int, db: Session = Depends(get_db)):
    chunks = db.query(KnowledgeChunk).filter(KnowledgeChunk.SubjectId == subject_id).all()
    return [{"chunkId": c.ChunkId, "topicName": c.TopicName, "week": c.Week,
             "contentLength": len(c.Content) if c.Content else 0,
             "preview": (c.Content or "")[:200]} for c in chunks]


@router.get("/knowledge-content/{topic_name}")
def get_knowledge_content(topic_name: str, db: Session = Depends(get_db)):
    decoded = urllib.parse.unquote(topic_name)
    chunks  = db.query(KnowledgeChunk).filter(KnowledgeChunk.TopicName == decoded).all()
    if not chunks:
        return {"content": "", "chunksFound": 0, "topicName": decoded}
    content = "\n\n---\n\n".join(c.Content for c in chunks if c.Content)
    return {"content": content[:15000], "chunksFound": len(chunks), "topicName": decoded}


@router.delete("/knowledge-chunks/{chunk_id}")
def delete_knowledge_chunk(chunk_id: int, db: Session = Depends(get_db)):
    chunk = db.query(KnowledgeChunk).filter(KnowledgeChunk.ChunkId == chunk_id).first()
    if not chunk:
        raise HTTPException(status_code=404, detail="Chunk not found.")
    db.delete(chunk)
    db.commit()
    return {"success": True, "deleted": chunk_id}


@router.get("/topic-questions/{subject_id}")
def get_topic_questions(subject_id: int, topic_name: str, db: Session = Depends(get_db)):
    decoded   = urllib.parse.unquote(topic_name)
    questions = (db.query(Question).join(Quiz, Question.QuizId == Quiz.QuizId)
                 .filter(Quiz.SubjectId == subject_id, Quiz.TopicName == decoded).all())
    return [{"questionId": q.QuestionId, "questionText": q.QuestionText,
             "optionA": q.OptionA, "optionB": q.OptionB,
             "optionC": q.OptionC, "optionD": q.OptionD,
             "correctOption": q.CorrectOption, "explanation": q.Explanation,
             "difficulty": q.quiz.Difficulty if q.quiz else "Medium",
             "type": q.quiz.QuizType if q.quiz else "Conceptual"} for q in questions]


@router.post("/regenerate-topic-questions/{subject_id}")
def regenerate_topic_questions(subject_id: int, topic_name: str,
                               db: Session = Depends(get_db)):
    decoded = urllib.parse.unquote(topic_name)
    chunks  = db.query(KnowledgeChunk).filter(
        KnowledgeChunk.SubjectId == subject_id,
        KnowledgeChunk.TopicName == decoded).all()
    if not chunks:
        raise HTTPException(status_code=404, detail=f"No content for '{decoded}'.")

    content = "\n\n".join(c.Content for c in chunks if c.Content).strip()
    if len(content) < 50:
        raise HTTPException(status_code=400, detail=f"Content too short for '{decoded}'.")

    for quiz in db.query(Quiz).filter(
            Quiz.SubjectId == subject_id, Quiz.TopicName == decoded).all():
        db.query(Question).filter(Question.QuizId == quiz.QuizId).delete()
    db.commit()

    co = get_cohere_client()
    questions = ai_generate_questions(co, decoded, content[:5000])
    _save_questions(db, subject_id, decoded, questions)

    return [{"questionId": idx + 1, "questionText": q.get("question", ""),
             "optionA": q.get("option_a", ""), "optionB": q.get("option_b", ""),
             "optionC": q.get("option_c", ""), "optionD": q.get("option_d", ""),
             "correctOption": q.get("correct", "").upper(),
             "explanation": q.get("explanation", ""),
             "difficulty": q.get("difficulty", "Medium"),
             "type": q.get("type", "Conceptual")} for idx, q in enumerate(questions)]