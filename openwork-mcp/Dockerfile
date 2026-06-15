FROM python:3.12-slim

WORKDIR /app

RUN pip install --no-cache-dir fastapi uvicorn httpx pydantic

COPY main.py .

EXPOSE 8765

CMD ["python", "main.py"]
