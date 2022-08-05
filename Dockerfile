FROM python:3.10.6-slim as base

LABEL org.opencontainers.image.source https://github.com/denys-pidlisnyi/aiohttp-websockets

ARG DOCKER_USER_ID=1000
ARG DOCKER_GROUP_ID=1000

ENV PYTHONUNBUFFERED 1

RUN groupadd -g ${DOCKER_GROUP_ID} user \
    && useradd --shell /bin/bash -u $DOCKER_USER_ID -g $DOCKER_GROUP_ID -o -c "" -m user

RUN pip install --no-cache -U pip setuptools pipenv \
    && rm -rf /root/.cache/pip

COPY --chown=user:user ./Pipfile ./Pipfile.lock /opt/server/

WORKDIR /opt/server/

RUN pipenv install --deploy --system \
    && pipenv --clear


FROM base as local

USER root

RUN pipenv install --deploy --system --dev \
    && pipenv --clear

USER user

# CMD ["python", "-m", "aiohttp.web", "-H", "0.0.0.0", "-P", "8080", "main:create_app"]
CMD ["adev", "runserver", "-p", "8000", "--livereload"]

FROM base as live

COPY --chown=user:user . /opt/server/

CMD ["gunicorn", "main:create_app()", "--bind", "0.0.,0.0", " --worker-class", "aiohttp.GunicornWebWorker", "--workers", "1", "--access-logfile", "-", "--error-logfile", "-"]
