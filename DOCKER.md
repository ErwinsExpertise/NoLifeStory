# Docker Usage Guide for NoLifeWzToNx

This guide explains how to use Docker to build and run NoLifeWzToNx for converting WZ files to NX format, without installing any dependencies manually.

## Prerequisites

- Docker installed on your system ([Get Docker](https://docs.docker.com/get-docker/))
- WZ files you want to convert (e.g., Data.wz, Character.wz, etc.)

## Quick Start

### Option 1: Pull Pre-built Image from GHCR (Recommended)

The easiest way to get started is to pull the pre-built image from GitHub Container Registry:

```bash
docker pull ghcr.io/erwinsexpertise/nolifestory:latest
```

Then use it with:

```bash
docker run --rm -v "$(pwd):/data" ghcr.io/erwinsexpertise/nolifestory:latest Data.wz --client
```

**Benefits:**
- No build time required
- Multi-platform support (amd64, arm64)
- Automatically updated on each release

### Option 2: Build the Docker Image Locally

If you prefer to build from source, from the repository root directory:

```bash
docker build -t nolifewztonx .
```

This creates a Docker image named `nolifewztonx` with all dependencies included.

### 2. Convert WZ Files

#### Using Pre-built Image from GHCR

If you pulled the image from GHCR:

```bash
docker run --rm -v "$(pwd):/data" ghcr.io/erwinsexpertise/nolifestory:latest Data.wz --client
```

#### Using Locally Built Image

If you built the image locally:

```bash
docker run --rm -v "$(pwd):/data" nolifewztonx Data.wz --client
```

#### Basic Usage (Current Directory)

If your WZ files are in the current directory:

```bash
docker run --rm -v "$(pwd):/data" nolifewztonx Data.wz --client
```

**What this does:**
- `--rm` removes the container after it finishes
- `-v "$(pwd):/data"` mounts your current directory to `/data` in the container
- `Data.wz` is the file to convert
- `--client` flag makes the output usable for NoLifeClient

#### Convert Files from a Specific Directory

If your WZ files are in a different directory:

**Linux/macOS:**
```bash
docker run --rm -v "/path/to/wz/files:/data" nolifewztonx Data.wz --client
```

**Windows (PowerShell):**
```powershell
docker run --rm -v "${PWD}:/data" nolifewztonx Data.wz --client
```

**Windows (Command Prompt):**
```cmd
docker run --rm -v "%cd%:/data" nolifewztonx Data.wz --client
```

### 3. Convert Multiple Files or Directories

Convert all WZ files in a directory:

```bash
docker run --rm -v "$(pwd):/data" nolifewztonx . --client
```

The program will automatically find and convert all `.wz` and `.img` files in the mounted directory.

## Command Options

NoLifeWzToNx supports the following flags:

- `--client` or `-c`: Create NX files for NoLifeClient (includes audio and sprites)
- `--server` or `-s`: Create NX files for server use (data only, smaller files)
- `--lz4hc` or `-h`: Use high compression LZ4 (slower but smaller output)

### Examples:

**Client mode with high compression:**
```bash
docker run --rm -v "$(pwd):/data" nolifewztonx Data.wz --client --lz4hc
```

**Server mode (lightweight):**
```bash
docker run --rm -v "$(pwd):/data" nolifewztonx Data.wz --server
```

**Process all files in a folder:**
```bash
docker run --rm -v "$(pwd):/data" nolifewztonx ./wz-files --client
```

## Output Files

- Input: `Data.wz`
- Output: `Data.nx` (created in the same directory as the input file)
- Log: `NoLifeWzToNx.log` (created in the mounted directory)

## Troubleshooting

### Permission Issues (Linux/macOS)

If output files are created with root ownership, you can fix permissions:

```bash
sudo chown -R $USER:$USER .
```

Or run the container with your user ID:

```bash
docker run --rm -v "$(pwd):/data" -u $(id -u):$(id -g) nolifewztonx Data.wz --client
```

### Windows Path Issues

If mounting drives on Windows doesn't work, ensure Docker has access to the drive:
1. Open Docker Desktop
2. Go to Settings → Resources → File Sharing
3. Add the drive/directory you want to mount

### Container Can't Find Files

Make sure:
1. The file path is relative to the mounted directory
2. File names are spelled correctly (case-sensitive on Linux)
3. The directory is properly mounted with `-v`

## Advanced Usage

### Interactive Shell (for debugging)

Access a shell inside the container:

```bash
docker run --rm -it -v "$(pwd):/data" --entrypoint /bin/bash nolifewztonx
```

Then run commands manually:
```bash
NoLifeWzToNx Data.wz --client
ls -la
```

### Building for Development

Build with debug symbols:

```bash
docker build -t nolifewztonx:debug --target builder .
```

### Multi-Platform Images

Build for different architectures:

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t nolifewztonx:latest .
```

## Supported Platforms

The Docker image works on:
- ✅ Linux (x86_64, arm64)
- ✅ macOS (Intel and Apple Silicon via Docker Desktop)
- ✅ Windows 10/11 (via Docker Desktop or WSL2)

## Image Details

- **Base Image**: Ubuntu 22.04 LTS
- **Size**: ~83 MB (runtime image)
- **Architecture**: Multi-platform support (amd64, arm64)
- **Registry**: GitHub Container Registry (GHCR)

### Available Image Tags

The image is published to `ghcr.io/erwinsexpertise/nolifestory` with the following tags:

- `latest` - Latest build from the main/master branch
- `main` or `master` - Latest build from the respective branch
- `v1.0.0`, `v1.0`, `v1` - Semantic version tags (when releases are created)
- `main-sha-<commit>` - Specific commit builds

**Example:**
```bash
# Pull latest version
docker pull ghcr.io/erwinsexpertise/nolifestory:latest

# Pull specific version
docker pull ghcr.io/erwinsexpertise/nolifestory:v1.0.0

# Pull specific commit
docker pull ghcr.io/erwinsexpertise/nolifestory:main-sha-abc1234
```

## Getting Help

For issues specific to:
- **Docker setup**: See [Docker documentation](https://docs.docker.com/)
- **NoLifeWzToNx usage**: See the main [README.md](README.md)
- **File format questions**: Check the [NoLifeStory project documentation](https://github.com/ErwinsExpertise/NoLifeStory)
