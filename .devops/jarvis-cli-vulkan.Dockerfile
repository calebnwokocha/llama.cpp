ARG UBUNTU_VERSION=jammy

FROM ubuntu:$UBUNTU_VERSION AS build

# Install build tools
RUN apt update && apt install -y git build-essential cmake wget libgomp1

# Install Vulkan SDK
RUN wget -qO - https://packages.lunarg.com/lunarg-signing-key-pub.asc | apt-key add - && \
    wget -qO /etc/apt/sources.list.d/lunarg-vulkan-jammy.list https://packages.lunarg.com/vulkan/lunarg-vulkan-jammy.list && \
    apt update -y && \
    apt-get install -y vulkan-sdk

# Build it
WORKDIR /app
COPY . .
RUN cmake -B build -DGGML_VULKAN=1 && \
    cmake --build build --config Release --target jarvis-cli

# Clean up
WORKDIR /
RUN cp /app/build/bin/jarvis-cli /jarvis-cli && \
    rm -rf /app

ENV LC_ALL=C.utf8

ENTRYPOINT [ "/jarvis-cli" ]
