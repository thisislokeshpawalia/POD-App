from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates

from app.database import Base, engine
from app.routers import auth, farmers

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Subsidy Delivery Partner API",
    description="Backend for delivery partner authentication and farmer management",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

templates = Jinja2Templates(directory=str(Path(__file__).parent / "templates"))

app.include_router(auth.router)
app.include_router(farmers.router)


@app.get("/")
def root():
    return {
        "message": "Subsidy Delivery Partner API",
        "docs": "/docs",
        "add_farmer_form": "/admin/add-farmer",
    }


@app.get("/admin/add-farmer", response_class=HTMLResponse)
def add_farmer_form(request: Request):
    return templates.TemplateResponse("add_farmer.html", {"request": request})
