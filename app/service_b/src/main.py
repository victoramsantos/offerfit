import os

import httpx
from fastapi import FastAPI
from fastapi.responses import JSONResponse

# Service B
SERVICE_B_HOST = "0.0.0.0"
SERVICE_B_PORT = int(os.getenv("APP_PORT", "8012"))

# Core URL where Service A is available
SERVICE_A_PORT = int(os.getenv("SERVICE_A_PORT", "8011"))
SERVICE_A_HOST = os.getenv("SERVICE_A_HOST", "0.0.0.0")
SERVICE_A_URL = f"{SERVICE_A_HOST}:{SERVICE_A_PORT}"

app = FastAPI(
    title="Service B FastAPI Client",
    version="0.1.0",
)

@app.get("/health")
def health():
    return JSONResponse(
        {
            "Status": "Success"
        }
    )

@app.get("/ping_service_a")
def ping_service_a() -> JSONResponse:
    with httpx.Client() as client:
        response_from_a = client.get(f"{SERVICE_A_URL}/ping")

        response = f"{response_from_a.json()['message']} (via Service B)"

        return JSONResponse({
            "message": response
        })


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host=SERVICE_B_HOST, port=SERVICE_B_PORT)
