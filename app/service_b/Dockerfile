FROM python:3.11-alpine

WORKDIR /app
COPY src/requirements.txt /app
COPY src/main.py /app

RUN python -m pip install -r requirements.txt

ENV APP_PORT=8012
EXPOSE ${APP_PORT}

ENV SERVICE_A_PORT=8011
EXPOSE ${SERVICE_A_PORT}

CMD ["python", "/app/main.py"]