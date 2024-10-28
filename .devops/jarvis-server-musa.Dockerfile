ARG UBUNTU_VERSION=22.04
# This needs to generally match the container host's environment.
ARG MUSA_VERSION=rc3.1.0
# Target the MUSA build image
ARG BASE_MUSA_DEV_CONTAINER=mthreads/musa:${MUSA_VERSION}-devel-ubuntu${UBUNTU_VERSION}
# Target the MUSA runtime image
ARG BASE_MUSA_RUN_CONTAINER=mthreads/musa:${MUSA_VERSION}-runtime-ubuntu${UBUNTU_VERSION}

FROM ${BASE_MUSA_DEV_CONTAINER} AS build

RUN apt-get update && \
    apt-get install -y build-essential git cmake libcurl4-openssl-dev

WORKDIR /app

COPY . .

RUN cmake -B build -DGGML_MUSA=ON -DJARVIS_CURL=ON ${CMAKE_ARGS} -DCMAKE_EXE_LINKER_FLAGS=-Wl,--allow-shlib-undefined . && \
    cmake --build build --config Release --target jarvis-server -j$(nproc)

FROM ${BASE_MUSA_RUN_CONTAINER} AS runtime

RUN apt-get update && \
    apt-get install -y libcurl4-openssl-dev libgomp1 curl

COPY --from=build /app/build/ggml/src/libggml.so /libggml.so
COPY --from=build /app/build/src/libjarvis.so /libjarvis.so
COPY --from=build /app/build/bin/jarvis-server /jarvis-server

# Must be set to 0.0.0.0 so it can listen to requests from host machine
ENV JARVIS_ARG_HOST=0.0.0.0

HEALTHCHECK CMD [ "curl", "-f", "http://localhost:8080/health" ]

ENTRYPOINT [ "/jarvis-server" ]