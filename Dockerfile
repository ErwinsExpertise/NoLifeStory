# Multi-stage Dockerfile for NoLifeWzToNx
# Stage 1: Build environment
FROM ubuntu:22.04 AS builder

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    libboost-filesystem-dev \
    libboost-system-dev \
    zlib1g-dev \
    liblz4-dev \
    libsquish-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /build

# Copy only the necessary source files for wztonx
COPY CMakeLists.txt /build/
COPY src/wztonx /build/src/wztonx/

# Create build directory and compile
RUN mkdir -p /build/build && \
    cd /build/build && \
    cmake -DCMAKE_BUILD_TYPE=Release \
          -DBUILD_NX=OFF \
          -DBUILD_CLIENT=OFF \
          -DBUILD_WZTONX=ON \
          -DBUILD_NXBENCH=OFF \
          .. && \
    make -j$(nproc)

# Stage 2: Runtime environment (lightweight)
FROM ubuntu:22.04 AS runtime

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    libboost-filesystem1.74.0 \
    libboost-system1.74.0 \
    zlib1g \
    liblz4-1 \
    libsquish0 \
    && rm -rf /var/lib/apt/lists/*

# Copy the compiled binary from builder stage
COPY --from=builder /build/build/src/wztonx/NoLifeWzToNx /usr/local/bin/NoLifeWzToNx

# Create a working directory for file operations
# Users will mount their WZ files here as a volume
WORKDIR /data

# Set the entrypoint to the executable
ENTRYPOINT ["/usr/local/bin/NoLifeWzToNx"]

# Default command - will list files in /data if no arguments provided
CMD ["."]
