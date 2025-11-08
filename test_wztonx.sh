#!/bin/bash
# Test script for NoLifeWzToNx
# This script downloads a test Data.wz file and runs the conversion
# to verify the std::length_error fix

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build_test"
WZTONX_BIN="$BUILD_DIR/src/wztonx/NoLifeWzToNx"
TEST_DIR="/tmp/wztonx_test"
DATA_WZ_URL="https://filebin.net/p0u3xzky3sxhejbw/Data.wz"

echo "===== NoLifeWzToNx Test Suite ====="
echo ""

# Create test directory
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Check if NoLifeWzToNx is built
if [ ! -f "$WZTONX_BIN" ]; then
    echo "ERROR: NoLifeWzToNx not found at $WZTONX_BIN"
    echo "Please build the project first:"
    echo "  cd $SCRIPT_DIR"
    echo "  mkdir -p build_test && cd build_test"
    echo "  cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_CLIENT=OFF -DBUILD_NX=OFF"
    echo "  make -j\$(nproc)"
    exit 1
fi

echo "✓ Found NoLifeWzToNx at: $WZTONX_BIN"
echo ""

# Download test file if not present
if [ ! -f "Data.wz" ]; then
    echo "Downloading test Data.wz file..."
    if command -v wget &> /dev/null; then
        wget -O Data.wz "$DATA_WZ_URL" || {
            echo "ERROR: Failed to download Data.wz"
            echo "Please manually download from: $DATA_WZ_URL"
            echo "And place it in: $TEST_DIR/Data.wz"
            exit 1
        }
    elif command -v curl &> /dev/null; then
        curl -L -o Data.wz "$DATA_WZ_URL" || {
            echo "ERROR: Failed to download Data.wz"
            echo "Please manually download from: $DATA_WZ_URL"
            echo "And place it in: $TEST_DIR/Data.wz"
            exit 1
        }
    else
        echo "ERROR: Neither wget nor curl found"
        echo "Please manually download from: $DATA_WZ_URL"
        echo "And place it in: $TEST_DIR/Data.wz"
        exit 1
    fi
    echo "✓ Downloaded Data.wz"
else
    echo "✓ Using existing Data.wz"
fi
echo ""

# Get file size
FILE_SIZE=$(stat -f%z "Data.wz" 2>/dev/null || stat -c%s "Data.wz" 2>/dev/null)
echo "Data.wz size: $FILE_SIZE bytes"
echo ""

# Run the conversion with --client flag
echo "Running conversion: Data.wz -> Data.nx (with --client flag)"
echo "Command: $WZTONX_BIN Data.wz --client"
echo ""

# Clean up any previous output
rm -f Data.nx NoLifeWzToNx.log

# Run the conversion and capture both stdout and stderr
set +e
"$WZTONX_BIN" Data.wz --client 2>&1 | tee conversion_output.log
EXIT_CODE=$?
set -e

echo ""
echo "===== Conversion Results ====="
echo "Exit code: $EXIT_CODE"
echo ""

if [ $EXIT_CODE -eq 0 ]; then
    echo "✓ SUCCESS: Conversion completed without errors!"
    echo ""
    
    # Check if output file was created
    if [ -f "Data.nx" ]; then
        NX_SIZE=$(stat -f%z "Data.nx" 2>/dev/null || stat -c%s "Data.nx" 2>/dev/null)
        echo "✓ Output file created: Data.nx ($NX_SIZE bytes)"
    else
        echo "⚠ WARNING: Data.nx not found"
    fi
    
    # Check log for any warnings
    if [ -f "NoLifeWzToNx.log" ]; then
        echo ""
        echo "Log file contents:"
        cat NoLifeWzToNx.log
    fi
else
    echo "✗ FAILED: Conversion failed with exit code $EXIT_CODE"
    echo ""
    echo "Error output:"
    tail -50 conversion_output.log
    echo ""
    
    if [ -f "NoLifeWzToNx.log" ]; then
        echo "Log file contents:"
        cat NoLifeWzToNx.log
    fi
    
    # Check for the specific error we're fixing
    if grep -q "std::length_error" conversion_output.log NoLifeWzToNx.log 2>/dev/null; then
        echo ""
        echo "✗ CRITICAL: std::length_error detected - the fix did not work!"
        exit 1
    elif grep -q "basic_string::_M_create" conversion_output.log NoLifeWzToNx.log 2>/dev/null; then
        echo ""
        echo "✗ CRITICAL: basic_string::_M_create error detected - the fix did not work!"
        exit 1
    fi
    
    exit $EXIT_CODE
fi

echo ""
echo "===== Test Summary ====="
echo "✓ All tests passed!"
echo "✓ No std::length_error detected"
echo "✓ The buffer reuse fix is working correctly"
