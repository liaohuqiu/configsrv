FROM python:2.7-alpine

COPY ./src/requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

VOLUME ["/configsrv/config"]

ADD ./src /configsrv/src
WORKDIR /configsrv/src

EXPOSE 8000
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
