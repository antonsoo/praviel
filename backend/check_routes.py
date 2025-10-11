#!/usr/bin/env python3
"""Check what routes are actually registered in the FastAPI app."""

import sys

if sys.platform == "win32":
    import io

    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

from app.main import app

print("=== REGISTERED ROUTES ===\n")
print("Quest-related routes:")
for route in app.routes:
    if hasattr(route, "path") and "/quest" in route.path:
        methods = getattr(route, "methods", set())
        print(f"  {list(methods)[0] if methods else 'GET':6s} {route.path}")

print("\nAll API routes:")
for route in app.routes:
    if hasattr(route, "path") and route.path.startswith("/api/"):
        methods = getattr(route, "methods", set())
        print(f"  {list(methods)[0] if methods else 'GET':6s} {route.path}")
