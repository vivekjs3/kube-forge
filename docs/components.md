# Talos Linux Components Breakdown

This document enumerates the Talos system daemons and utilities:
- **`talosctl`**: Administrative CLI executing gRPC commands over port 50000.
- **`machined`**: Custom PID 1 managing initialization, state transitions, and disk mounts.
- **`apid`**: The endpoint for all `talosctl` client calls.
- **`trustd`**: Coordinates internal trust and CA bundle propagation across nodes.
