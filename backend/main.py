from fastapi import FastAPI

# Create an instance of the FastAPI class
app = FastAPI(
    title="Ancient Languages AI Project",
    description="API for the Linguistic Kernel and AI Services.",
    version="0.1.0",
)

@app.get("/")
def read_root():
    """
    Root endpoint to confirm the API is running.
    """
    return {"message": "Welcome to the Linguistic Kernel API. The system is online."}