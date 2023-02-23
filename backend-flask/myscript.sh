#!/bin/bash
docker run -p 4567:4567 aws-bootcamp-cruddur-2023-backend-flask:latest python3 -m flask run --host=0.0.0.0 --port=4567