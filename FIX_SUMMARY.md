# Fix Summary: std::length_error in WZ File Parsing

## Issue
After PR #6, users were still experiencing this error when converting Data.wz files:
```
terminate called after throwing an instance of 'std::length_error'
  what():  basic_string::_M_create
```

## Root Cause
The `read_enc_string()` function in `src/wztonx/wztonx.cpp` uses a member variable `wstr_buf` (a `std::u16string`) as a reusable buffer for string operations. The buffer was being reused across multiple calls without being cleared, causing it to accumulate data.

### Specific Problem Scenario
1. Function reads a wide string (UTF-16) → `wstr_buf.resize(1000)` → buffer contains 1000 chars
2. Function reads an ASCII string with high-bit chars → uses `std::back_inserter(wstr_buf)`
3. The `back_inserter` **appends** to the existing 1000 chars instead of replacing them
4. After many calls, `wstr_buf` grows beyond `std::string::max_size()` → throws `std::length_error`

## The Fix
Added two `wstr_buf.clear()` calls to ensure the buffer starts fresh:

**Location 1 (line 371):** Before `wstr_buf.resize(slen)` when processing UTF-16 strings
```cpp
auto mask = 0xAAAAu;
wstr_buf.clear();  // ← ADDED
wstr_buf.resize(slen);
```

**Location 2 (line 400):** Before `std::back_inserter(wstr_buf)` when converting CP1252 strings
```cpp
if (std::any_of(str_buf.begin(), str_buf.end(),
    [](char const & c) { return static_cast<uint8_t>(c) >= 0x80; })) {
    wstr_buf.clear();  // ← ADDED
    std::transform(str_buf.cbegin(), str_buf.cend(), std::back_inserter(wstr_buf),
        [](char c) { return cp1252[static_cast<unsigned char>(c)]; });
```

## Why This Works
- `clear()` empties the buffer but doesn't deallocate memory (efficient)
- `back_inserter()` now appends to an empty buffer instead of accumulated data
- `resize()` operates on a clean buffer, preventing unexpected growth
- Buffer reuse is preserved (no performance impact), but state is properly reset

## Impact
- **Minimal change:** Only 2 lines added
- **No performance impact:** `clear()` is O(1) and doesn't deallocate
- **Surgical fix:** Only touches the problematic function
- **Backward compatible:** No API or behavior changes

## Testing
See [TESTING.md](TESTING.md) for detailed testing procedures.

Quick test:
```bash
./test_wztonx.sh
```

This will download a test Data.wz file and verify the conversion completes without throwing `std::length_error`.
