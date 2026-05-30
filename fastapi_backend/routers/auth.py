from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import User
from schemas import LoginRequest, SignupRequest, UserResponse, ApiResponse

router = APIRouter(prefix="/api/auth", tags=["auth"])

@router.post("/login")
def login(request: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.Email == request.email, User.Password == request.password).first()
    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    return {
        "success": True,
        "data": {
            "id": user.Id,
            "name": user.Name,
            "email": user.Email,
            "role": user.Role or "student"
        }
    }

@router.post("/signup")
def signup(request: SignupRequest, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.Email == request.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already exists")
    
    user = User(Name=request.name, Email=request.email, Password=request.password, Role="student")
    db.add(user)
    db.commit()
    db.refresh(user)
    
    return {
        "success": True,
        "data": {
            "id": user.Id,
            "name": user.Name,
            "email": user.Email,
            "role": user.Role or "student"
        }
    }