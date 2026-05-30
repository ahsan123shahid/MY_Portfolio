from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine, Base
from routers import auth, subject, notes, quiz, explain, admin, pdf

# Create tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="BaraniQuiz API", version="1.0.0")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=[
        "*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router)
app.include_router(subject.router)
app.include_router(notes.router)
app.include_router(quiz.router)
app.include_router(explain.router)
app.include_router(admin.router)
app.include_router(pdf.router)

@app.get("/")
def root():
    return {"message": "BaraniQuiz API is running!"}

@app.get("/health")
def health():
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)