#!/usr/bin/env python3
# Optional: delegates to ./run to keep CLI in POSIX shell (BIDS Apps convention).
import os, sys, subprocess, shlex
cmd = ["/usr/local/bin/run"] + sys.argv[1:]
sys.exit(subprocess.call(cmd))