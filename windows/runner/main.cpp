#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <vector>
#include <string>

#include "flutter_window.h"
#include "utils.h"

struct FindInstanceParams {
  HWND hwndFound = nullptr;
};

BOOL CALLBACK FindInstanceWindowProc(HWND hwnd, LPARAM lParam) {
  FindInstanceParams* params = reinterpret_cast<FindInstanceParams*>(lParam);
  wchar_t className[256];
  if (::GetClassNameW(hwnd, className, 256) > 0) {
    if (::wcscmp(className, L"FLUTTER_RUNNER_WIN32_WINDOW") == 0) {
      if (::GetPropW(hwnd, L"JA_IQ5_REFLASH_INSTANCE") == (HANDLE)1) {
        params->hwndFound = hwnd;
        return FALSE; // Stop search
      }
    }
  }
  return TRUE;
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Named Mutex check to prevent duplicate launches
  HANDLE hMutex = ::CreateMutexW(nullptr, TRUE, L"Local\\JA_IQ5_REFLASH_SingleInstance");
  if (hMutex == nullptr) {
    return EXIT_FAILURE;
  }

  if (::GetLastError() == ERROR_ALREADY_EXISTS) {
    ::CloseHandle(hMutex);

    // Scan for existing window instance
    HWND existing_hwnd = nullptr;
    for (int i = 0; i < 20; ++i) { // Retry for up to 2 seconds
      FindInstanceParams params;
      ::EnumWindows(FindInstanceWindowProc, reinterpret_cast<LPARAM>(&params));
      if (params.hwndFound != nullptr) {
        existing_hwnd = params.hwndFound;
        break;
      }
      ::Sleep(100);
    }

    if (existing_hwnd != nullptr) {
      if (::IsIconic(existing_hwnd)) {
        ::ShowWindow(existing_hwnd, SW_RESTORE);
      } else {
        ::ShowWindow(existing_hwnd, SW_SHOW);
      }
      ::SetForegroundWindow(existing_hwnd);
      ::SetFocus(existing_hwnd);
    }
    return EXIT_SUCCESS;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"JA IQ5 Reflash", origin, size)) {
    ::CloseHandle(hMutex);
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  // Mark this window instance with our property tag
  ::SetPropW(window.GetHandle(), L"JA_IQ5_REFLASH_INSTANCE", (HANDLE)1);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  // Remove the property and release mutex on exit
  ::RemovePropW(window.GetHandle(), L"JA_IQ5_REFLASH_INSTANCE");
  ::CloseHandle(hMutex);

  ::CoUninitialize();

  // Auto-restart Qualcomm service on exit to restore system state
  WinExec("sc start qcmtusvc", SW_HIDE);

  return EXIT_SUCCESS;
}
