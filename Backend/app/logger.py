import logging
import sys
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler(f'logs/app-{datetime.now().strftime("%Y%m%d")}.log')
    ]
)

def get_logger(name):
    return logging.getLogger(name) 