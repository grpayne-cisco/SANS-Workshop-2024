FROM alpine:3.20

RUN apk update && \ 
    apk add git python3 py3-pip gcc python3-dev musl-dev linux-headers libffi-dev bash  && \
    ln -sf python3 /usr/bin/python   && \
    ln -sf pip3 /usr/bin/pip && \ 
    ARCH=$(arch)  && \
    ARCH_TERRAFORM=$(arch)  && \
    if [[ "$ARCH" == "aarch64" ]]; then ARCH="arm64"; fi && \
    if [[ "$ARCH_TERRAFORM" == "x86_64" ]]; then ARCH_TERRAFORM="amd64"; fi && \
    SYSTEM=$(uname) && \
    echo "https://github.com/open-policy-agent/conftest/releases/download/v0.55.0/conftest_0.55.0_${SYSTEM}_${ARCH}.tar.gz" && \
    wget "https://github.com/open-policy-agent/conftest/releases/download/v0.55.0/conftest_0.55.0_${SYSTEM}_${ARCH}.tar.gz" && \
    tar xzf conftest_0.55.0_${SYSTEM}_${ARCH}.tar.gz && \
    mv conftest /usr/local/bin && \
    pip install botocore==1.34.148 --break-system-packages && \
    pip install localstack --break-system-packages && \
    pip install awscli --break-system-packages && \ 
    pip install terraform-local --break-system-packages && \
    echo "https://releases.hashicorp.com/terraform/1.8.5/terraform_1.8.5_linux_${ARCH_TERRAFORM}.zip" && \
    wget "https://releases.hashicorp.com/terraform/1.8.5/terraform_1.8.5_linux_${ARCH_TERRAFORM}.zip"  && \
    unzip terraform_1.8.5_linux_${ARCH_TERRAFORM}.zip && \
    mv terraform /usr/local/bin

ENTRYPOINT [ "sh" ]