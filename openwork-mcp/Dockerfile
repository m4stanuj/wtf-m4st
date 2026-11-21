FROM node:22-alpine AS dashboard-build

WORKDIR /src/dashboard
COPY dashboard/package*.json ./
RUN npm ci
COPY dashboard/ ./
RUN npm run build

FROM python:3.12-slim

WORKDIR /app
ENV M4ST_DASHBOARD_HOST=0.0.0.0

COPY openwork-mcp/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

COPY openwork-mcp/main.py /app/openwork-mcp/main.py
COPY --from=dashboard-build /src/dashboard/dist /app/dashboard/dist

RUN mkdir -p /app/logs

WORKDIR /app/openwork-mcp
EXPOSE 8765

CMD ["python", "main.py"]
