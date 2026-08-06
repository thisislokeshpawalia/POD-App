from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    mongodb_url: str = "mongodb+srv://podapp796_db_user:obqxukNI0z20czpq@cluster0.ehucwbg.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0"
    secret_key: str = "7294b4b2e83151811eefcbdf7e324abef8a1e5088f1dc344c2de0cc7b9ffae"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24 * 7

    class Config:
        env_file = ".env"

settings = Settings()
