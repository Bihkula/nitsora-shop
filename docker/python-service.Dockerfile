FROM python:3.12-slim

ARG SERVICE

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    SERVICE_NAME=${SERVICE}

WORKDIR /app

COPY libs/shopcommon /tmp/shopcommon
COPY services/${SERVICE}/requirements.txt /tmp/requirements.txt
RUN pip install /tmp/shopcommon -r /tmp/requirements.txt \
    && rm -rf /tmp/shopcommon /tmp/requirements.txt

COPY services/${SERVICE}/app ./app

RUN useradd --uid 10001 --no-create-home appuser
USER 10001

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]