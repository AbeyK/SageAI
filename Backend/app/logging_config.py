import logging
import sys


def setup_logging():
    """Configures basic structured logging for the application."""
    logger = logging.getLogger("meditation_app")
    logger.setLevel(logging.INFO)  # Set default logging level

    # Create a handler for stdout
    handler = logging.StreamHandler(sys.stdout)
    handler.setLevel(logging.INFO)

    # Create a formatter and set it for the handler
    formatter = logging.Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(module)s:%(lineno)d - %(message)s"
    )
    handler.setFormatter(formatter)

    # Add the handler to the logger
    # Check if handlers are already added to prevent duplication during reloads with uvicorn
    if not logger.handlers:
        logger.addHandler(handler)

    # Example of how to get a logger elsewhere in the app:
    # import logging
    # logger = logging.getLogger("meditation_app")
    # logger.info("This is an info message.")

    print("Logging configured.")
    return logger


# Initialize logging when this module is imported
# setup_logging() # Call it from main.py or where app is initialized
