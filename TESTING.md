# Testing the std::length_error Fix

This document describes how to test the fix for the `std::length_error: basic_string::_M_create` issue.

## The Problem

The issue occurred when processing WZ files with many strings containing high-bit ASCII characters. The `wstr_buf` buffer in the `read_enc_string()` function was being reused without clearing, causing it to grow unboundedly until it exceeded the maximum string size.

## The Fix

Two lines were added to clear the `wstr_buf` buffer before each use:
1. Before `wstr_buf.resize(slen)` when processing wide strings
2. Before using `std::back_inserter(wstr_buf)` when converting ASCII strings

## Automated Testing

### Prerequisites

1. Build the project:
   ```bash
   mkdir -p build_test && cd build_test
   cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_CLIENT=OFF -DBUILD_NX=OFF
   make -j$(nproc)
   cd ..
   ```

2. Download the test Data.wz file from: https://filebin.net/p0u3xzky3sxhejbw/Data.wz

### Running the Test

Run the automated test script:
```bash
./test_wztonx.sh
```

The script will:
- Check that NoLifeWzToNx is built
- Download Data.wz if not already present
- Run the conversion with the `--client` flag
- Check for the `std::length_error` or `basic_string::_M_create` errors
- Report success or failure

### Manual Testing

If you prefer to test manually:

```bash
cd /tmp
# Download Data.wz manually or use wget/curl
# wget https://filebin.net/p0u3xzky3sxhejbw/Data.wz

# Run the conversion
/path/to/NoLifeWzToNx Data.wz --client
```

### Expected Results

**Before the fix:**
```
NoLifeWzToNx
Copyright © 2014 Peter Atashian
Licensed under GNU Affero General Public License
Converts WZ files into NX files
Data.wz -> Data.nx
terminate called after throwing an instance of 'std::length_error'
  what():  basic_string::_M_create
```

**After the fix:**
```
NoLifeWzToNx
Copyright © 2014 Peter Atashian
Licensed under GNU Affero General Public License
Converts WZ files into NX files
Data.wz -> Data.nx
Working on Data.wz
Parsing input.......Done!
Opening output......Done!
Writing nodes.......Done!
Writing strings.....Done!
Writing audio.......Done!
Writing bitmaps.....Done!
Took X seconds
```

## Testing in Docker

You can also test using Docker:

```bash
# Build the Docker image
docker build -t nolifewztonx-test .

# Run the conversion
docker run --rm -v "$(pwd):/data" nolifewztonx-test Data.wz --client
```

## Verification

The fix is successful if:
1. ✓ The conversion completes without throwing `std::length_error`
2. ✓ A Data.nx file is created
3. ✓ The process exits with code 0
4. ✓ No error messages appear in the output or log file

## Technical Details

The fix addresses buffer reuse by ensuring `wstr_buf` is cleared:
- **Location 1** (line 371): Before `resize()` when processing UTF-16 encoded strings
- **Location 2** (line 400): Before `back_inserter()` when converting CP1252 strings to UTF-16

This prevents accumulation of data from previous string reads, which was causing the buffer to exceed `max_size()` and throw `std::length_error`.
