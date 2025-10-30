"""
Load testing script using Locust for PRAVIEL API.

Usage:
    # Install locust first
    pip install locust

    # Run with web UI
    locust -f scripts/load_test.py --host https://api.praviel.com

    # Run headless
    locust -f scripts/load_test.py --host https://api.praviel.com \
        --users 100 --spawn-rate 10 --run-time 5m --headless

    # Run with different host
    locust -f scripts/load_test.py --host http://localhost:8000

Target Benchmarks:
    - 500 concurrent users without degradation
    - p95 latency < 500ms for reader endpoints
    - p95 latency < 3s for lesson generation
    - No 5xx errors under normal load
"""

from locust import HttpUser, LoadTestShape, TaskSet, between, task


class ReaderBehavior(TaskSet):
    """Simulates a user reading and analyzing ancient texts."""

    def on_start(self):
        """Setup - executed once per simulated user when they start."""
        # For authenticated endpoints, you would login here
        # response = self.client.post("/api/v1/auth/login", json={
        #     "email": "loadtest@praviel.com",
        #     "password": "test_password"
        # })
        # self.token = response.json()["access_token"]
        pass

    @task(5)
    def read_greek_text(self):
        """Read and analyze Classical Greek text (most common use case)."""
        self.client.post(
            "/reader/analyze",
            json={
                "text": "Μῆνιν ἄειδε θεὰ Πηληϊάδεω Ἀχιλῆος οὐλομένην",
                "language_code": "grc-cls",
            },
            name="/reader/analyze (Greek)",
        )

    @task(3)
    def read_latin_text(self):
        """Read and analyze Latin text."""
        self.client.post(
            "/reader/analyze",
            json={
                "text": "Arma virumque cano, Troiae qui primus ab oris",
                "language_code": "lat",
            },
            name="/reader/analyze (Latin)",
        )

    @task(2)
    def read_hebrew_text(self):
        """Read and analyze Biblical Hebrew text."""
        self.client.post(
            "/reader/analyze",
            json={
                "text": "בְּרֵאשִׁית בָּרָא אֱלֹהִים אֵת הַשָּׁמַיִם וְאֵת הָאָרֶץ",
                "language_code": "hbo",
            },
            name="/reader/analyze (Hebrew)",
        )

    @task(1)
    def list_languages(self):
        """List available languages (lightweight endpoint)."""
        self.client.get("/api/v1/languages", name="/api/v1/languages")

    @task(1)
    def health_check(self):
        """Health check endpoint."""
        self.client.get("/health", name="/health")


class LessonBehavior(TaskSet):
    """Simulates a user generating and completing lessons."""

    def on_start(self):
        """Setup - login for authenticated endpoints."""
        # In production, use real test accounts
        pass

    @task(2)
    def generate_beginner_lesson(self):
        """Generate a beginner lesson (expensive operation)."""
        self.client.post(
            "/api/v1/lesson/generate",
            json={
                "language_code": "lat",
                "difficulty": "beginner",
                "lesson_type": "vocabulary",
            },
            name="/api/v1/lesson/generate (beginner)",
        )

    @task(1)
    def generate_intermediate_lesson(self):
        """Generate an intermediate lesson."""
        self.client.post(
            "/api/v1/lesson/generate",
            json={
                "language_code": "grc-cls",
                "difficulty": "intermediate",
                "lesson_type": "grammar",
            },
            name="/api/v1/lesson/generate (intermediate)",
        )

    @task(1)
    def get_lesson_progress(self):
        """Get lesson progress (requires authentication)."""
        # This would need a valid auth token
        # headers = {"Authorization": f"Bearer {self.token}"}
        # self.client.get("/api/v1/progress", headers=headers)
        pass


class ChatBehavior(TaskSet):
    """Simulates a user chatting with AI tutor."""

    @task(3)
    def chat_with_tutor(self):
        """Send a message to AI tutor."""
        self.client.post(
            "/api/v1/chat",
            json={
                "message": "How do I conjugate the verb 'amo' in Latin?",
                "language_code": "lat",
                "conversation_id": None,
            },
            name="/api/v1/chat",
        )

    @task(1)
    def get_chat_history(self):
        """Get chat history (requires authentication)."""
        # This would need a valid auth token
        pass


class PravielUser(HttpUser):
    """
    Simulates a typical PRAVIEL user.

    The user will perform tasks from different behavior sets with different weights:
    - 60% reader tasks (most common)
    - 25% lesson tasks
    - 15% chat tasks
    """

    wait_time = between(1, 5)  # Wait 1-5 seconds between tasks (realistic user behavior)

    tasks = {
        ReaderBehavior: 6,  # 60% of time
        LessonBehavior: 2,  # 20% of time
        ChatBehavior: 2,  # 20% of time
    }

    def on_start(self):
        """Called when a simulated user starts."""
        # Any one-time setup per user (e.g., login)
        pass


class HeavyUser(HttpUser):
    """
    Simulates a power user who generates many lessons.

    This user type stresses the expensive lesson generation endpoints.
    """

    wait_time = between(2, 8)

    tasks = {LessonBehavior: 1}


class ReadOnlyUser(HttpUser):
    """
    Simulates a user who only reads texts.

    This user type stresses the reader endpoints with high frequency.
    """

    wait_time = between(0.5, 2)  # Faster reading

    tasks = {ReaderBehavior: 1}


class DailyLoadShape(LoadTestShape):
    """
    A load shape that simulates daily traffic patterns.

    - Ramps up in the morning (6am-9am)
    - Peak during day (9am-5pm)
    - Ramps down in evening (5pm-8pm)
    - Low traffic at night (8pm-6am)
    """

    time_limit = 3600  # 1 hour test

    def tick(self):
        """Return the desired user count and spawn rate at each time step."""
        run_time = self.get_run_time()

        if run_time < self.time_limit:
            # Simulate daily pattern (compressed into 1 hour)
            # 0-15min: ramp up (50 users)
            # 15-45min: peak traffic (200 users)
            # 45-60min: ramp down (50 users)

            if run_time < 900:  # First 15 minutes - ramp up
                user_count = int(50 * (run_time / 900))
                spawn_rate = 2
            elif run_time < 2700:  # 15-45 minutes - peak
                user_count = 200
                spawn_rate = 5
            else:  # 45-60 minutes - ramp down
                user_count = int(200 - (150 * (run_time - 2700) / 900))
                spawn_rate = 2

            return (user_count, spawn_rate)

        return None


# Example commands:
"""
# Basic test with web UI
locust -f scripts/load_test.py --host https://api.praviel.com

# Headless test with specific user distribution
locust -f scripts/load_test.py --host https://api.praviel.com \\
    --users 500 --spawn-rate 10 --run-time 10m --headless \\
    --user-classes PravielUser:60,ReadOnlyUser:30,HeavyUser:10

# Use custom load shape for realistic traffic
locust -f scripts/load_test.py --host https://api.praviel.com \\
    --shape DailyLoadShape --headless

# Test against local development server
locust -f scripts/load_test.py --host http://localhost:8000

# Generate CSV reports
locust -f scripts/load_test.py --host https://api.praviel.com \\
    --users 100 --spawn-rate 5 --run-time 5m --headless \\
    --csv=load_test_results --html=load_test_report.html
"""
