FROM python:3.12

WORKDIR /root
COPY ./*.sh /root

RUN apt update -y \
    && apt install -y jq highlight vim \
    && pip install dictknife \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip && ./aws/install && rm -f awscliv2.zip
