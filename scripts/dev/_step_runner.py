#!/usr/bin/env python3
"""Step runner with idle/hard timeouts, heartbeat, and sentinel output."""

from __future__ import annotations

import argparse
import os
import queue
import signal
import subprocess
import sys
import threading
import time
from pathlib import Path

HEARTBEAT_INTERVAL = 5.0
DEFAULT_IDLE_TIMEOUT = 120.0
DEFAULT_HARD_TIMEOUT = 900.0


class StepRunnerError(Exception):
    """Raised when the step runner fails before invoking the command."""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(prog="step", add_help=True)
    parser.add_argument("--name", required=True, help="Human-readable step name")
    parser.add_argument("--log", help="Log file path")
    parser.add_argument(
        "--heartbeat",
        help="Heartbeat file path (modtime touched every heartbeat interval)",
    )
    parser.add_argument(
        "--idle-timeout",
        type=float,
        default=DEFAULT_IDLE_TIMEOUT,
        help="Seconds without output before considering the step idle",
    )
    parser.add_argument(
        "--hard-timeout",
        type=float,
        default=DEFAULT_HARD_TIMEOUT,
        help="Max wall-clock seconds before aborting the step",
    )
    parser.add_argument(
        "--cwd",
        help="Working directory for the command",
    )
    parser.add_argument("command", nargs=argparse.REMAINDER, help="Command to run")

    args = parser.parse_args()

    if args.command and args.command[0] == "--":
        args.command = args.command[1:]
    if not args.command:
        parser.error("command is required after '--'")

    if args.idle_timeout is not None and args.idle_timeout <= 0:
        args.idle_timeout = None
    if args.hard_timeout is not None and args.hard_timeout <= 0:
        args.hard_timeout = None

    return args


def touch(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.touch()


def kill_tree(proc: subprocess.Popen) -> None:
    if proc.poll() is not None:
        return
    try:
        if os.name == "nt":
            subprocess.run(
                ["taskkill", "/PID", str(proc.pid), "/T", "/F"],
                check=False,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        else:
            os.killpg(proc.pid, signal.SIGTERM)
            time.sleep(0.5)
            if proc.poll() is None:
                os.killpg(proc.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass
    except PermissionError:
        if proc.poll() is None:
            proc.kill()
    finally:
        try:
            proc.wait(timeout=5)
        except Exception:
            pass


def launch_process(args: argparse.Namespace) -> subprocess.Popen:
    cwd = Path(args.cwd).resolve() if args.cwd else None
    if cwd is not None and not cwd.exists():
        raise StepRunnerError(f"working directory does not exist: {cwd}")

    creationflags = 0
    preexec_fn = None
    if os.name == "nt":
        creationflags = subprocess.CREATE_NEW_PROCESS_GROUP  # type: ignore[attr-defined]
    else:
        preexec_fn = os.setsid

    try:
        proc = subprocess.Popen(
            args.command,
            cwd=str(cwd) if cwd else None,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
            universal_newlines=True,
            encoding="utf-8",
            errors="replace",
            preexec_fn=preexec_fn,
            creationflags=creationflags,
        )
    except FileNotFoundError as exc:
        raise StepRunnerError(str(exc)) from exc

    if proc.stdout is None:
        raise StepRunnerError("failed to capture command stdout")
    return proc


def main() -> int:
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except AttributeError:
        pass
    opts = parse_args()
    root = Path(__file__).resolve().parents[2]
    artifacts = root / "artifacts"

    log_path = Path(opts.log) if opts.log else artifacts / f"step_{opts.name}.log"
    hb_path = Path(opts.heartbeat) if opts.heartbeat else artifacts / f"step_{opts.name}.hb"
    log_path.parent.mkdir(parents=True, exist_ok=True)
    heartbeat_enabled = True

    queue_lines: "queue.Queue[str | None]" = queue.Queue()
    start_time = time.monotonic()
    last_output = start_time
    last_heartbeat = 0.0
    sentinel_reason: str | None = None
    sentinel_emitted = False

    def emit(status: str, reason: str | None = None) -> None:
        nonlocal sentinel_emitted
        if sentinel_emitted:
            return
        if status == "OK":
            print(f"::STEP::{opts.name}::OK", flush=True)
        else:
            detail = reason or "unknown"
            print(f"::STEP::{opts.name}::FAIL::{detail}", flush=True)
        sentinel_emitted = True

    try:
        proc = launch_process(opts)
    except StepRunnerError as error:
        emit("FAIL", "launch_error")
        print(str(error), file=sys.stderr)
        return 2

    def reader() -> None:
        try:
            assert proc.stdout is not None
            for line in proc.stdout:
                queue_lines.put(line)
        except Exception as exc:  # pragma: no cover - defensive
            queue_lines.put(f"[step] stdout reader error: {exc}\n")
        finally:
            queue_lines.put(None)

    reader_thread = threading.Thread(target=reader, daemon=True)
    reader_thread.start()

    with log_path.open("w", encoding="utf-8") as log_file:
        reader_finished = False
        process_finished = False
        try:
            while True:
                try:
                    line = queue_lines.get(timeout=0.5)
                except queue.Empty:
                    line = ""

                now = time.monotonic()

                if heartbeat_enabled and (now - last_heartbeat) >= HEARTBEAT_INTERVAL:
                    touch(hb_path)
                    last_heartbeat = now

                if line is None:
                    reader_finished = True
                elif line != "":
                    last_output = now
                    log_file.write(line)
                    log_file.flush()
                    print(line, end="", flush=True)

                if not process_finished and proc.poll() is not None:
                    process_finished = True

                if process_finished and (reader_finished or queue_lines.empty()):
                    break

                if opts.hard_timeout is not None and (now - start_time) > opts.hard_timeout:
                    sentinel_reason = "hard_timeout"
                    kill_tree(proc)
                    process_finished = True

                if (
                    sentinel_reason is None
                    and opts.idle_timeout is not None
                    and (now - last_output) > opts.idle_timeout
                ):
                    sentinel_reason = "idle_timeout"
                    kill_tree(proc)
                    process_finished = True
        except KeyboardInterrupt:
            sentinel_reason = "interrupted"
            kill_tree(proc)
            process_finished = True
        finally:
            reader_thread.join(timeout=2)
            while True:
                try:
                    pending = queue_lines.get_nowait()
                except queue.Empty:
                    break
                if pending is None:
                    break
                if pending:
                    log_file.write(pending)
                    log_file.flush()
                    print(pending, end="", flush=True)
            if heartbeat_enabled:
                touch(hb_path)

    return_code = proc.poll()
    if return_code is None:
        try:
            return_code = proc.wait(timeout=1)
        except subprocess.TimeoutExpired:
            return_code = -1

    if sentinel_reason:
        emit("FAIL", sentinel_reason)
        return 1

    if return_code != 0:
        reason = f"exit_{return_code}"
        if return_code and return_code < 0:
            reason = f"signal_{abs(return_code)}"
        emit("FAIL", reason)
        return int(return_code or 1)

    emit("OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
