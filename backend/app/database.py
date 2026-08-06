from pymongo import MongoClient
import pymongo
from app.config import settings

client = MongoClient(settings.mongodb_url, serverSelectionTimeoutMS=5000)
db = client["pody_db"]

def get_db():
    yield db
