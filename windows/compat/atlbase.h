#pragma once
#ifndef __ATLBASE_H__
#define __ATLBASE_H__

#include <windows.h>
#include <string>

/// Lightweight ATL CW2A fallback shim when MSVC ATL is not installed.
/// Converts wide string (LPCWSTR) to multi-byte string (UTF-8).
class CW2A {
public:
    CW2A(LPCWSTR wstr, UINT codePage = CP_UTF8) {
        if (!wstr) {
            str_ = "";
            return;
        }
        int len = WideCharToMultiByte(codePage, 0, wstr, -1, nullptr, 0, nullptr, nullptr);
        if (len > 1) {
            str_.resize(len - 1);
            WideCharToMultiByte(codePage, 0, wstr, -1, &str_[0], len, nullptr, nullptr);
        } else {
            str_ = "";
        }
    }

    operator const char*() const { return str_.c_str(); }
    operator std::string() const { return str_; }
    const char* m_psz() const { return str_.c_str(); }

private:
    std::string str_;
};

#endif // __ATLBASE_H__
