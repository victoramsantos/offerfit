FROM python:3.11-alpine

WORKDIR /app
COPY src/requirements.txt /app
COPY src/main.py /app

RUN python -m pip install -r requirements.txt

CMD ["python", "/app/main.py"]