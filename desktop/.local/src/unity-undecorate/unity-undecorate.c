#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <X11/Xlib.h>
#include <X11/Xatom.h>

extern char *program_invocation_short_name;

static int (*real_XMapWindow)(Display *, Window) = NULL;
static int (*real_XMapRaised)(Display *, Window) = NULL;

struct MotifHints {
    unsigned long flags;
    unsigned long functions;
    unsigned long decorations;
    long inputMode;
    unsigned long status;
};

static int is_unity_process(void) {
    if (!program_invocation_short_name) return 0;
    if (strcmp(program_invocation_short_name, "Unity") == 0 ||
        strcmp(program_invocation_short_name, "Unity.bin") == 0) {
        return 1;
    }
    return 0;
}

static void undecorate_if_main_window(Display *dpy, Window w) {
    if (!dpy || w == None) return;

    if (!is_unity_process()) return;

    const char *disabled = getenv("UNITY_REMOVE_TITLEBAR");
    if (disabled && strcmp(disabled, "0") == 0) {
        return;
    }

    int debug = (getenv("UNITY_UNDECORATE_DEBUG") != NULL);

    // Check window attributes
    XWindowAttributes attr;
    if (XGetWindowAttributes(dpy, w, &attr)) {
        if (attr.override_redirect) {
            if (debug) fprintf(stderr, "[unity-undecorate] 0x%lx is override-redirect, skipping\n", w);
            return;
        }
    }

    // Check transient for hint (dialogs, popups)
    Window transient_for = None;
    if (XGetTransientForHint(dpy, w, &transient_for) &&
        transient_for != None &&
        transient_for != RootWindow(dpy, DefaultScreen(dpy))) {
        if (debug) fprintf(stderr, "[unity-undecorate] 0x%lx is transient for 0x%lx, skipping\n", w, transient_for);
        return;
    }

    // Check _NET_WM_WINDOW_TYPE
    Atom prop_type = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE", True);
    if (prop_type != None) {
        Atom actual_type;
        int actual_format;
        unsigned long nitems, bytes_after;
        unsigned char *prop = NULL;
        if (XGetWindowProperty(dpy, w, prop_type, 0, 1024, False,
                               XA_ATOM, &actual_type, &actual_format,
                               &nitems, &bytes_after, &prop) == Success && prop) {
            Atom *atoms = (Atom *)prop;
            Atom dialog_atom = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE_DIALOG", True);
            Atom tooltip_atom = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE_TOOLTIP", True);
            Atom menu_atom = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE_POPUP_MENU", True);
            Atom drop_atom = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE_DROPDOWN_MENU", True);
            int skip = 0;
            for (unsigned long i = 0; i < nitems; i++) {
                if (atoms[i] == dialog_atom || atoms[i] == tooltip_atom ||
                    atoms[i] == menu_atom || atoms[i] == drop_atom) {
                    skip = 1;
                    break;
                }
            }
            XFree(prop);
            if (skip) {
                if (debug) fprintf(stderr, "[unity-undecorate] 0x%lx is dialog/popup type, skipping\n", w);
                return;
            }
        }
    }

    // Apply Motif hints to remove decorations
    Atom motif_hints = XInternAtom(dpy, "_MOTIF_WM_HINTS", False);
    if (motif_hints != None) {
        struct MotifHints hints;
        hints.flags = 2;       // MWM_HINTS_DECORATIONS
        hints.functions = 0;
        hints.decorations = 0; // 0 = no decorations
        hints.inputMode = 0;
        hints.status = 0;

        XChangeProperty(dpy, w, motif_hints, motif_hints, 32, PropModeReplace,
                        (unsigned char *)&hints, 5);
        if (debug) fprintf(stderr, "[unity-undecorate] Successfully undecorated window 0x%lx\n", w);
    }
}

int XMapWindow(Display *dpy, Window w) {
    if (!real_XMapWindow) {
        real_XMapWindow = dlsym(RTLD_NEXT, "XMapWindow");
    }
    undecorate_if_main_window(dpy, w);
    return real_XMapWindow(dpy, w);
}

int XMapRaised(Display *dpy, Window w) {
    if (!real_XMapRaised) {
        real_XMapRaised = dlsym(RTLD_NEXT, "XMapRaised");
    }
    undecorate_if_main_window(dpy, w);
    return real_XMapRaised(dpy, w);
}

__attribute__((constructor))
static void unity_undecorate_init(void) {
    // Unset LD_PRELOAD so child processes (compilers, external editors, etc.) don't inherit it
    unsetenv("LD_PRELOAD");
}
