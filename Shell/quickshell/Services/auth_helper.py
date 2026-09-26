#!/usr/bin/env python3
import sys
import getpass
import os
import ctypes
import ctypes.util

def check_pam(user, password, service_name=b'vlock'):
    try:
        libpam = ctypes.CDLL(ctypes.util.find_library('pam') or 'libpam.so.0')
        libc = ctypes.CDLL(ctypes.util.find_library('c') or 'libc.so.6')

        # Explicit 64-bit return types to avoid pointer truncation
        libc.calloc.restype = ctypes.c_void_p
        libc.calloc.argtypes = [ctypes.c_size_t, ctypes.c_size_t]
        libc.strdup.restype = ctypes.c_void_p
        libc.strdup.argtypes = [ctypes.c_char_p]

        PAM_PROMPT_ECHO_OFF = 1
        PAM_PROMPT_ECHO_ON  = 2

        class PamMessage(ctypes.Structure):
            _fields_ = [('msg_style', ctypes.c_int), ('msg', ctypes.c_char_p)]

        class PamResponse(ctypes.Structure):
            _fields_ = [('resp', ctypes.c_void_p), ('resp_retcode', ctypes.c_int)]

        PAM_CONV_FUNC = ctypes.CFUNCTYPE(
            ctypes.c_int,
            ctypes.c_int,
            ctypes.POINTER(ctypes.POINTER(PamMessage)),
            ctypes.POINTER(ctypes.POINTER(PamResponse)),
            ctypes.c_void_p
        )

        class PamConv(ctypes.Structure):
            _fields_ = [('conv', PAM_CONV_FUNC), ('appdata_ptr', ctypes.c_void_p)]

        def conv_cb(n_messages, messages, p_response, appdata):
            arr = libc.calloc(n_messages, ctypes.sizeof(PamResponse))
            resp_array = ctypes.cast(arr, ctypes.POINTER(PamResponse))
            p_response[0] = resp_array

            for i in range(n_messages):
                msg_ptr = messages[i]
                if msg_ptr:
                    style = msg_ptr.contents.msg_style
                    if style in (PAM_PROMPT_ECHO_OFF, PAM_PROMPT_ECHO_ON):
                        resp_array[i].resp = libc.strdup(password.encode('utf-8'))
                        resp_array[i].resp_retcode = 0
            return 0

        conv_func = PAM_CONV_FUNC(conv_cb)
        conv = PamConv(conv_func, None)
        pamh = ctypes.c_void_p()

        res = libpam.pam_start(service_name, user.encode('utf-8'), ctypes.byref(conv), ctypes.byref(pamh))
        if res != 0:
            return False
        res = libpam.pam_authenticate(pamh, 0)
        libpam.pam_end(pamh, res)
        return res == 0
    except Exception:
        return False

def main():
    user = getpass.getuser()
    if len(sys.argv) > 1 and sys.argv[1] == "--user":
        print(user)
        sys.exit(0)

    # Read password without blocking
    password = sys.stdin.readline().rstrip('\r\n')
    if not password:
        print("FAILED")
        sys.exit(1)

    # Fast PAM verification on standard user lock services
    for s in [b'vlock', b'system-auth', b'su', b'passwd']:
        if check_pam(user, password, s):
            print("OK")
            sys.exit(0)

    print("FAILED")
    sys.exit(1)

if __name__ == '__main__':
    main()

