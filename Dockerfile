FROM minizinc/minizinc:edge

WORKDIR /leave-optimization

COPY . .

RUN apt update -y  \
    && apt install -y python3 \
    && apt install -y python3-pip 

RUN pip3 install -r requirements.txt

CMD ["python3", "generate_calendar.py"]
