import os
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from jose import JWTError, jwt
from passlib.context import CryptContext
from datetime import datetime, timedelta
from typing import Optional
from strawberry.fastapi import GraphQLRouter
from api.schema import schema
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm

# ===== JWT Configuration =====
SECRET_KEY = os.getenv("JWT_SECRET", "YOUR_SECRET_KEY")  # Change in production!
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 5

# ===== Password Hashing =====
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# ===== Authentication Setup =====
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# ===== Hardcoded Admin User (for demo) =====
HARDCODED_USER = {
    "username": "admin",
    "password": "$2b$12$8KHjAuAH5ApeWEXRSU.2mOnRtl.Oay.4kqAxlqqW3i1KmbiaY.yNW"  # bcrypt hash of "admin"
}

# ===== Auth Utilities =====
def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

# Print the actual stored hash for comparison
print(f"Stored hash: {HARDCODED_USER['password']}")

# Manually verify the password
test_result = pwd_context.verify("secret", HARDCODED_USER["password"])
print(f"Manual verification: {test_result}")

async def get_current_user(token: str = Depends(oauth2_scheme)) -> str:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username != HARDCODED_USER["username"]:
            raise credentials_exception
        return username
    except JWTError:
        raise credentials_exception

# ===== FastAPI App Setup =====
app = FastAPI()

# Allow CORS (adjust for production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# GraphQL Route
graphql_app = GraphQLRouter(schema)
app.include_router(graphql_app, prefix="/graphql")

# ===== Auth Endpoints =====
@app.post("/token")
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    if form_data.username != HARDCODED_USER["username"] or not verify_password(form_data.password, HARDCODED_USER["password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
        )
    access_token = create_access_token(data={"sub": form_data.username})
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "expires_in": ACCESS_TOKEN_EXPIRE_MINUTES * 60
    }

# ===== Protected Example Endpoint =====
@app.get("/protected")
async def protected_route(current_user: str = Depends(get_current_user)):
    return {"message": f"Hello admin {current_user}"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host="0.0.0.0",  # Allows access from any device on your network
        port=8000,
        reload=True  # Optional: Auto-reload on code changes (remove in production)
    )