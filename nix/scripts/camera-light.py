# Turns the Logitech Litra Glow lights on while a program uses a camera.
# When no program uses a camera, the script turns the lights off.
#
# The script waits on inotify events (file events from the kernel):
#
# - A program opens or closes a /dev/video* node.
# - A camera or a light connects, or gets new permissions.
#
# After a group of events, the script finds the processes that have a
# /dev/video* node open, as fuser does. The events alone cannot tell if a
# camera is open: the kernel merges identical events that are not read
# yet, so a count of opens and closes is not correct. Zoom closes the
# camera when you stop the video.
#
# The light protocol comes from https://github.com/timrogers/litra-rs.

import glob
import os
import sys

from inotify_simple import INotify, flags

# Milliseconds to collect the events of a group. Programs like Zoom open
# each camera for some milliseconds every 3 seconds to read its properties.
# Such an open is over before the script looks, so the light does not
# change.
SETTLE = 300

LIGHT_HID_ID = "HID_ID=0003:0000046D:0000C900\n"

WATCH_DEV = flags.CREATE | flags.ATTRIB
WATCH_CAMERA = flags.OPEN | flags.CLOSE_WRITE | flags.CLOSE_NOWRITE


def log(message):
    print(message, file=sys.stderr, flush=True)


def camera_in_use():
    """Return True if a process has a /dev/video* node open.

    The script sees only the processes of its user.
    """
    for pid in os.listdir("/proc"):
        if not pid.isdigit():
            continue
        try:
            fds = list(os.scandir(f"/proc/{pid}/fd"))
        except OSError:
            continue
        for fd in fds:
            try:
                if os.readlink(fd.path).startswith("/dev/video"):
                    return True
            except OSError:
                pass
    return False


def lights():
    """Return the hidraw node of each Litra Glow, by its HID instance.

    The HID instance changes when the light connects again.
    """
    found = {}
    for node in glob.glob("/sys/class/hidraw/hidraw*"):
        try:
            with open(os.path.join(node, "device", "uevent")) as f:
                if LIGHT_HID_ID not in f.read():
                    continue
        except OSError:
            continue
        instance = os.path.realpath(os.path.join(node, "device"))
        found[instance] = "/dev/" + os.path.basename(node)
    return found


def set_power(path, on):
    """Send the power state to the light. Return True if this worked."""
    report = bytes([0x11, 0xFF, 0x04, 0x1C, 1 if on else 0]).ljust(20, b"\0")
    try:
        fd = os.open(path, os.O_WRONLY)
        try:
            os.write(fd, report)
        finally:
            os.close(fd)
        return True
    except OSError as e:
        log(f"cannot turn {path} {'on' if on else 'off'}: {e}")
        return False


def watch_cameras(inotify):
    """Add a watch to each /dev/video* node.

    The kernel gives the same watch again for a node that has a watch. A new
    node can have no permissions yet. The next ATTRIB event of /dev starts a
    new attempt.
    """
    for path in glob.glob("/dev/video*"):
        try:
            inotify.add_watch(path, WATCH_CAMERA)
        except OSError as e:
            log(f"cannot watch {path}: {e}")


def main():
    inotify = INotify()
    dev = inotify.add_watch("/dev", WATCH_DEV)
    watch_cameras(inotify)

    on = False
    # The lights that have the current state. At the start, the script does
    # not touch the lights.
    done = set(lights())
    while True:
        in_use = camera_in_use()
        if in_use != on:
            on, done = in_use, set()
            log(f"camera {'in use' if on else 'not in use'}")
        # A light that connects again gets the state when udev gives the
        # user access to it. That access is an ATTRIB event of /dev.
        # Each connection is a new HID instance, so forget the old ones.
        found = lights()
        done &= found.keys()
        for instance, path in found.items():
            if instance not in done and set_power(path, on):
                done.add(instance)

        for event in inotify.read(read_delay=SETTLE):
            # A new camera, a camera with new permissions, or lost events.
            new_camera = event.wd == dev and event.name.startswith("video")
            if new_camera or event.mask & flags.Q_OVERFLOW:
                watch_cameras(inotify)


if __name__ == "__main__":
    main()
