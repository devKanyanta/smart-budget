import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://student_kwacha_user:student_kwacha_dev_password@localhost:5432/student_kwacha")
MODEL_PATH = os.getenv("MODEL_PATH", "./models")
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")

# Confidence threshold for auto-categorization
CATEGORIZATION_CONFIDENCE_THRESHOLD = 0.5

# Minimum data points for savings prediction
MIN_SAVINGS_DATA_POINTS = 3
