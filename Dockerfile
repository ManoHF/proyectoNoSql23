# Dockerfile
FROM python:3.8

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt
RUN sudo apt-get install jq

COPY . /app

# Specify the command to run on container start
CMD ["python", "load_mongo_neo.py"]

