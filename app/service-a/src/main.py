import os

from fastapi import FastAPI
from fastapi.responses import JSONResponse

# Service A
SERVICE_A_HOST = "0.0.0.0"
SERVICE_A_PORT = int(os.getenv("APP_PORT", "8012"))

app = FastAPI(
    title="Service A FastAPI Client",
    version="0.1.0",
)


@app.get("/health")
def health():
    return JSONResponse(
        {
            "Status": "Success"
        }
    )

@app.get("/ping")
def ping():
    return JSONResponse(
        {
            "message": "Greetings from Service A!"
        }
    )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host=SERVICE_A_HOST, port=SERVICE_A_PORT)




