"""Centralized email templates for all PRAVIEL emails.

This module provides all email templates used throughout the application:
- Email verification
- Streak reminders
- SRS review reminders
- Achievement notifications
- Weekly progress digests
- Onboarding sequences
- Re-engagement campaigns
- Password changed notifications

All templates support both HTML and plain text formats.
"""

from __future__ import annotations

from datetime import datetime


class EmailTemplates:
    """Centralized email template provider."""

    @staticmethod
    def get_base_style() -> str:
        """Get common CSS styles for all emails."""
        return """
        <style>
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
                line-height: 1.6;
                color: #333;
                margin: 0;
                padding: 0;
                background-color: #f5f7fa;
            }
            .container {
                max-width: 600px;
                margin: 0 auto;
                background: white;
            }
            .header {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 30px 20px;
                text-align: center;
                border-radius: 8px 8px 0 0;
            }
            .header h1 {
                margin: 0;
                font-size: 28px;
                font-weight: 600;
            }
            .content {
                padding: 30px 20px;
            }
            .button {
                display: inline-block;
                background: #667eea;
                color: white !important;
                padding: 14px 32px;
                text-decoration: none;
                border-radius: 6px;
                font-weight: 600;
                margin: 20px 0;
            }
            .button:hover {
                background: #5568d3;
            }
            .highlight-box {
                background: #f0f4ff;
                padding: 20px;
                border-radius: 8px;
                border-left: 4px solid #667eea;
                margin: 20px 0;
            }
            .stats-table {
                width: 100%;
                margin: 20px 0;
            }
            .stats-table td {
                padding: 15px;
                text-align: center;
            }
            .stat-value {
                font-size: 32px;
                font-weight: bold;
                color: #667eea;
                display: block;
            }
            .stat-label {
                font-size: 14px;
                color: #666;
                display: block;
            }
            .footer {
                text-align: center;
                padding: 20px;
                color: #999;
                font-size: 12px;
                border-top: 1px solid #eee;
            }
            .footer a {
                color: #667eea;
                text-decoration: none;
            }
            .warning-box {
                background: #fef3c7;
                border-left: 4px solid #f59e0b;
                padding: 15px;
                margin: 20px 0;
                border-radius: 4px;
            }
            .achievement-badge {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 40px 20px;
                text-align: center;
                border-radius: 12px;
                margin: 20px 0;
            }
            .achievement-badge img {
                width: 80px;
                height: 80px;
                margin-bottom: 15px;
            }
            ul {
                padding-left: 20px;
            }
            ul li {
                margin: 8px 0;
            }
        </style>
        """

    # ========================================================================
    # EMAIL VERIFICATION
    # ========================================================================

    @staticmethod
    def verification_email(username: str, verification_url: str) -> tuple[str, str, str]:
        """Email verification template.

        Args:
            username: User's username
            verification_url: Full URL with verification token

        Returns:
            Tuple of (subject, html_body, text_body)
        """
        subject = "Verify Your PRAVIEL Account"

        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            {EmailTemplates.get_base_style()}
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>Welcome to PRAVIEL!</h1>
                </div>
                <div class="content">
                    <p>Hi <strong>{username}</strong>,</p>

                    <p>Welcome to PRAVIEL! You're one step away from unlocking <strong>46 ancient languages</strong>.</p>

                    <p>Click the button below to verify your email and activate your account:</p>

                    <div style="text-align: center;">
                        <a href="{verification_url}" class="button">
                            Verify Email Address
                        </a>
                    </div>

                    <div class="warning-box">
                        <strong>⏰ This link expires in 24 hours.</strong>
                    </div>

                    <p>Or copy and paste this link into your browser:</p>
                    <p style="word-break: break-all; color: #667eea; font-size: 12px;">{verification_url}</p>

                    <p>If you didn't create an account, you can safely ignore this email.</p>

                    <p>Welcome aboard!<br>
                    The PRAVIEL Team</p>
                </div>
                <div class="footer">
                    <p>PRAVIEL | Learning Ancient Languages<br>
                    <a href="https://praviel.com">praviel.com</a></p>
                </div>
            </div>
        </body>
        </html>
        """

        text = f"""
Welcome to PRAVIEL, {username}!

You're one step away from unlocking 46 ancient languages.

Verify your email to activate your account:
{verification_url}

⏰ This link expires in 24 hours.

If you didn't create an account, you can safely ignore this email.

Welcome aboard!
The PRAVIEL Team

---
PRAVIEL | Learning Ancient Languages
praviel.com
        """.strip()

        return subject, html, text

    # ========================================================================
    # STREAK REMINDER
    # ========================================================================

    @staticmethod
    def streak_reminder(
        username: str,
        streak_days: int,
        xp_needed: int,
        quick_lesson_url: str,
        settings_url: str,
    ) -> tuple[str, str, str]:
        """Streak reminder email template.

        Args:
            username: User's username
            streak_days: Current streak count
            xp_needed: XP needed to maintain streak
            quick_lesson_url: Direct link to start a lesson
            settings_url: Link to notification settings

        Returns:
            Tuple of (subject, html_body, text_body)
        """
        # Personalized emoji and status based on streak length
        if streak_days >= 100:
            emoji = "🔥"
            streak_status = f"legendary {streak_days}-day"
        elif streak_days >= 30:
            emoji = "⚡"
            streak_status = f"amazing {streak_days}-day"
        elif streak_days >= 7:
            emoji = "🌟"
            streak_status = f"solid {streak_days}-day"
        else:
            emoji = "💫"
            streak_status = f"{streak_days}-day"

        estimated_minutes = max(5, (xp_needed // 10))  # Rough estimate

        subject = f"{emoji} Don't break your {streak_days}-day streak!"

        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            {EmailTemplates.get_base_style()}
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>{emoji} Keep your {streak_status} streak alive!</h1>
                </div>
                <div class="content">
                    <p>Hi <strong>{username}</strong>,</p>

                    <p>You're just <strong>{xp_needed} XP</strong> away from maintaining your streak.
                    That's about <strong>{estimated_minutes} minutes</strong> of practice!</p>

                    <div class="highlight-box">
                        <h3 style="margin-top: 0; color: #667eea;">⚡ Quick Win Options:</h3>
                        <ul style="margin-bottom: 0;">
                            <li>Complete 1 vocabulary review (2 min)</li>
                            <li>Practice 5 SRS cards (3 min)</li>
                            <li>Read one sentence with analysis (5 min)</li>
                        </ul>
                    </div>

                    <div style="text-align: center;">
                        <a href="{quick_lesson_url}" class="button">
                            Practice Now ({xp_needed} XP to go!)
                        </a>
                    </div>

                    <p style="color: #666; font-size: 14px; text-align: center;">
                        Your streak ends at midnight. Don't let {streak_days} days go to waste!
                    </p>

                    <p>Keep up the great work! 💪</p>
                </div>
                <div class="footer">
                    <p>PRAVIEL | Learning Ancient Languages<br>
                    Don't want daily reminders? <a href="{settings_url}">Update your preferences</a></p>
                </div>
            </div>
        </body>
        </html>
        """

        text = f"""
{emoji} Keep your {streak_status} streak alive!

Hi {username},

You're just {xp_needed} XP away from maintaining your streak.
That's about {estimated_minutes} minutes of practice!

⚡ Quick Win Options:
• Complete 1 vocabulary review (2 min)
• Practice 5 SRS cards (3 min)
• Read one sentence with analysis (5 min)

Practice now: {quick_lesson_url}

Your streak ends at midnight. Don't let {streak_days} days go to waste!

Keep up the great work! 💪

---
Don't want daily reminders? Update your preferences: {settings_url}
        """.strip()

        return subject, html, text

    # ========================================================================
    # SRS REVIEW REMINDER
    # ========================================================================

    @staticmethod
    def srs_review_reminder(
        username: str,
        cards_due: int,
        estimated_minutes: int,
        review_url: str,
        settings_url: str,
    ) -> tuple[str, str, str]:
        """SRS review reminder email template.

        Args:
            username: User's username
            cards_due: Number of cards due for review
            estimated_minutes: Estimated time to complete reviews
            review_url: Direct link to SRS review page
            settings_url: Link to notification settings

        Returns:
            Tuple of (subject, html_body, text_body)
        """
        subject = f"📚 {cards_due} cards ready for review"

        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            {EmailTemplates.get_base_style()}
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>Good morning, {username}! 📚</h1>
                </div>
                <div class="content">
                    <p>You have <strong>{cards_due} cards</strong> waiting for review today.</p>

                    <div class="highlight-box" style="text-align: center;">
                        <p style="margin: 0; font-size: 18px; color: #667eea;">
                            ⏱️ Estimated time: <strong>~{estimated_minutes} minutes</strong>
                        </p>
                    </div>

                    <p><strong>Why review now?</strong></p>
                    <ul>
                        <li>Reinforce what you learned before you forget</li>
                        <li>Build long-term retention through spaced repetition</li>
                        <li>Keep your SRS algorithm optimal</li>
                    </ul>

                    <div style="text-align: center;">
                        <a href="{review_url}" class="button">
                            Start Reviewing
                        </a>
                    </div>

                    <p style="color: #666; font-size: 14px; text-align: center;">
                        <strong>Pro tip:</strong> Daily reviews are more effective than cramming!
                    </p>
                </div>
                <div class="footer">
                    <p>PRAVIEL | Learning Ancient Languages<br>
                    Don't want SRS reminders? <a href="{settings_url}">Update your preferences</a></p>
                </div>
            </div>
        </body>
        </html>
        """

        text = f"""
Good morning, {username}! 📚

You have {cards_due} cards waiting for review today.

⏱️ Estimated time: ~{estimated_minutes} minutes

Why review now?
• Reinforce what you learned before you forget
• Build long-term retention through spaced repetition
• Keep your SRS algorithm optimal

Start reviewing: {review_url}

Pro tip: Daily reviews are more effective than cramming!

---
Don't want SRS reminders? Update your preferences: {settings_url}
        """.strip()

        return subject, html, text

    # ========================================================================
    # ACHIEVEMENT UNLOCKED
    # ========================================================================

    @staticmethod
    def achievement_unlocked(
        username: str,
        achievement_name: str,
        achievement_description: str,
        achievement_icon_url: str,
        rarity_percent: float,
        achievements_url: str,
        share_url: str,
    ) -> tuple[str, str, str]:
        """Achievement unlocked email template.

        Args:
            username: User's username
            achievement_name: Name of the achievement
            achievement_description: Description of the achievement
            achievement_icon_url: URL to achievement icon/badge
            rarity_percent: Percentage of users who have this achievement
            achievements_url: Link to all achievements page
            share_url: Link to share achievement

        Returns:
            Tuple of (subject, html_body, text_body)
        """
        subject = f"🏆 Achievement Unlocked: {achievement_name}!"

        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            {EmailTemplates.get_base_style()}
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🎉 Congratulations!</h1>
                </div>
                <div class="content">
                    <p style="font-size: 18px; text-align: center;">You've unlocked:</p>

                    <div class="achievement-badge">
                        <img src="{achievement_icon_url}" alt="{achievement_name}">
                        <h2 style="margin: 0; font-size: 24px;">{achievement_name}</h2>
                        <p style="margin: 10px 0 0 0; opacity: 0.9;">{achievement_description}</p>
                    </div>

                    <p style="text-align: center; font-size: 16px; color: #666;">
                        Only <strong>{rarity_percent:.1f}%</strong> of learners reach this milestone!
                    </p>

                    <div style="text-align: center; margin: 30px 0;">
                        <a href="{share_url}" class="button" style="margin: 5px;">
                            Share Your Achievement
                        </a>
                        <a href="{achievements_url}" class="button" style="background: white; color: #667eea; border: 2px solid #667eea; margin: 5px;">
                            View All Achievements
                        </a>
                    </div>

                    <p style="text-align: center; color: #666;">What will you unlock next?</p>
                </div>
                <div class="footer">
                    <p>PRAVIEL | Learning Ancient Languages</p>
                </div>
            </div>
        </body>
        </html>
        """

        text = f"""
🎉 Congratulations, {username}!

You've unlocked: {achievement_name}

{achievement_description}

Only {rarity_percent:.1f}% of learners reach this milestone!

Share your achievement: {share_url}
View all achievements: {achievements_url}

What will you unlock next?

---
PRAVIEL | Learning Ancient Languages
        """.strip()

        return subject, html, text

    # ========================================================================
    # WEEKLY PROGRESS DIGEST
    # ========================================================================

    @staticmethod
    def weekly_digest_html(
        week_start: str,
        week_end: str,
    ) -> str:
        """Weekly progress digest HTML template (for broadcasts).

        Uses Resend template variables for personalization.

        Args:
            week_start: Start date of the week (formatted)
            week_end: End date of the week (formatted)

        Returns:
            HTML template with Resend variables
        """
        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            {EmailTemplates.get_base_style()}
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>Your Week in Review</h1>
                    <p style="margin: 10px 0 0 0; opacity: 0.9;">{week_start} - {week_end}</p>
                </div>
                <div class="content">
                    <p>Hi {{{{FIRST_NAME|there}}}},</p>

                    <p>Here's how you did this week:</p>

                    <table class="stats-table">
                        <tr>
                            <td>
                                <span class="stat-value">{{{{XP_THIS_WEEK|0}}}}</span>
                                <span class="stat-label">📊 XP Earned</span>
                            </td>
                            <td>
                                <span class="stat-value">{{{{STREAK_DAYS|0}}}}</span>
                                <span class="stat-label">🔥 Current Streak</span>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <span class="stat-value">{{{{LESSONS_THIS_WEEK|0}}}}</span>
                                <span class="stat-label">✅ Lessons Completed</span>
                            </td>
                            <td>
                                <span class="stat-value">{{{{SRS_REVIEWS|0}}}}</span>
                                <span class="stat-label">📚 SRS Reviews</span>
                            </td>
                        </tr>
                    </table>

                    <div class="highlight-box">
                        <h3 style="margin-top: 0; color: #667eea;">🎯 This Week's Goal</h3>
                        <p style="margin-bottom: 0;">Keep your streak alive for 7 more days!</p>
                    </div>

                    <div style="text-align: center; margin: 30px 0;">
                        <a href="https://app.praviel.com/lessons" class="button">
                            Continue Learning
                        </a>
                    </div>

                    <p style="color: #666; font-size: 14px;">
                        <strong>Pro tip:</strong> Consistency beats intensity. Even 5 minutes a day makes a difference!
                    </p>
                </div>
                <div class="footer">
                    <p>PRAVIEL | Learning Ancient Languages<br>
                    <a href="{{{{RESEND_UNSUBSCRIBE_URL}}}}">Unsubscribe from weekly digests</a></p>
                </div>
            </div>
        </body>
        </html>
        """
        return html

    # ========================================================================
    # ONBOARDING SEQUENCE
    # ========================================================================

    @staticmethod
    def onboarding_day1(username: str, first_lesson_url: str) -> tuple[str, str, str]:
        """Day 1 onboarding email template.

        Args:
            username: User's username
            first_lesson_url: URL to start first lesson

        Returns:
            Tuple of (subject, html_body, text_body)
        """
        subject = "Welcome to PRAVIEL! Here's how to start 🚀"

        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            {EmailTemplates.get_base_style()}
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>Welcome to PRAVIEL! 🚀</h1>
                </div>
                <div class="content">
                    <p>Hi <strong>{username}</strong>,</p>

                    <p>You've just joined thousands of learners mastering ancient languages. Here's how to get started:</p>

                    <div class="highlight-box">
                        <h3 style="margin-top: 0; color: #667eea;">📖 Step 1: Choose Your First Language</h3>
                        <p>Start with one of our top 4:</p>
                        <ul style="margin-bottom: 0;">
                            <li><strong>Classical Latin</strong> - The language of Rome</li>
                            <li><strong>Koine Greek</strong> - New Testament Greek</li>
                            <li><strong>Classical Greek</strong> - Homer, Plato, Sophocles</li>
                            <li><strong>Biblical Hebrew</strong> - Old Testament Hebrew</li>
                        </ul>
                    </div>

                    <div class="highlight-box">
                        <h3 style="margin-top: 0; color: #667eea;">⚡ Step 2: Complete Your First Lesson</h3>
                        <p style="margin-bottom: 0;">Just 5-10 minutes to get started. You'll learn:</p>
                        <ul style="margin-bottom: 0;">
                            <li>Core vocabulary</li>
                            <li>Basic grammar patterns</li>
                            <li>How to read authentic texts</li>
                        </ul>
                    </div>

                    <div style="text-align: center; margin: 30px 0;">
                        <a href="{first_lesson_url}" class="button">
                            Start Your First Lesson
                        </a>
                    </div>

                    <div class="highlight-box">
                        <h3 style="margin-top: 0; color: #667eea;">🎯 Step 3: Set Your Daily Goal</h3>
                        <p style="margin-bottom: 0;">We recommend starting with <strong>5-10 minutes per day</strong>. Small consistent efforts beat marathon sessions!</p>
                    </div>

                    <p>Ready to begin your journey through history?</p>
                </div>
                <div class="footer">
                    <p>PRAVIEL | Learning Ancient Languages<br>
                    Questions? Reply to this email anytime.</p>
                </div>
            </div>
        </body>
        </html>
        """

        text = f"""
Welcome to PRAVIEL! 🚀

Hi {username},

You've just joined thousands of learners mastering ancient languages. Here's how to get started:

📖 Step 1: Choose Your First Language
Start with one of our top 4:
• Classical Latin - The language of Rome
• Koine Greek - New Testament Greek
• Classical Greek - Homer, Plato, Sophocles
• Biblical Hebrew - Old Testament Hebrew

⚡ Step 2: Complete Your First Lesson
Just 5-10 minutes to get started. You'll learn:
• Core vocabulary
• Basic grammar patterns
• How to read authentic texts

Start your first lesson: {first_lesson_url}

🎯 Step 3: Set Your Daily Goal
We recommend starting with 5-10 minutes per day. Small consistent efforts beat marathon sessions!

Ready to begin your journey through history?

---
PRAVIEL | Learning Ancient Languages
Questions? Reply to this email anytime.
        """.strip()

        return subject, html, text

    @staticmethod
    def onboarding_day3(username: str, srs_url: str, texts_url: str) -> tuple[str, str, str]:
        """Day 3 onboarding email template.

        Args:
            username: User's username
            srs_url: URL to SRS system
            texts_url: URL to text library

        Returns:
            Tuple of (subject, html_body, text_body)
        """
        subject = "3 tips to accelerate your learning"

        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            {EmailTemplates.get_base_style()}
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>Pro Learning Tips 💡</h1>
                </div>
                <div class="content">
                    <p>Hi <strong>{username}</strong>,</p>

                    <p>You've been learning for a few days now! Here are 3 powerful techniques to accelerate your progress:</p>

                    <div class="highlight-box">
                        <h3 style="margin-top: 0; color: #667eea;">1️⃣ Use the SRS System Daily</h3>
                        <p>Our Spaced Repetition System helps you remember vocabulary forever:</p>
                        <ul>
                            <li>Review cards when they're due (not before)</li>
                            <li>Be honest with yourself on difficulty ratings</li>
                            <li>Aim for 10-20 reviews per day</li>
                        </ul>
                        <p><a href="{srs_url}" style="color: #667eea;">Start reviewing now →</a></p>
                    </div>

                    <div class="highlight-box">
                        <h3 style="margin-top: 0; color: #667eea;">2️⃣ Read Authentic Texts Early</h3>
                        <p>Don't wait until you're "ready"! Start reading real ancient texts now:</p>
                        <ul>
                            <li>Tap any word for instant analysis</li>
                            <li>Build vocabulary from context</li>
                            <li>See grammar in action</li>
                        </ul>
                        <p><a href="{texts_url}" style="color: #667eea;">Explore the text library →</a></p>
                    </div>

                    <div class="highlight-box">
                        <h3 style="margin-top: 0; color: #667eea;">3️⃣ Set Achievable Goals</h3>
                        <p style="margin-bottom: 0;"><strong>Quality over quantity:</strong></p>
                        <ul style="margin-bottom: 0;">
                            <li>5 focused minutes beats 30 distracted minutes</li>
                            <li>Consistency matters more than intensity</li>
                            <li>Build a daily habit you can maintain</li>
                        </ul>
                    </div>

                    <p>Keep up the great work! 🎉</p>
                </div>
                <div class="footer">
                    <p>PRAVIEL | Learning Ancient Languages</p>
                </div>
            </div>
        </body>
        </html>
        """

        text = f"""
Pro Learning Tips 💡

Hi {username},

You've been learning for a few days now! Here are 3 powerful techniques to accelerate your progress:

1️⃣ Use the SRS System Daily
Our Spaced Repetition System helps you remember vocabulary forever:
• Review cards when they're due (not before)
• Be honest with yourself on difficulty ratings
• Aim for 10-20 reviews per day
Start reviewing: {srs_url}

2️⃣ Read Authentic Texts Early
Don't wait until you're "ready"! Start reading real ancient texts now:
• Tap any word for instant analysis
• Build vocabulary from context
• See grammar in action
Explore texts: {texts_url}

3️⃣ Set Achievable Goals
Quality over quantity:
• 5 focused minutes beats 30 distracted minutes
• Consistency matters more than intensity
• Build a daily habit you can maintain

Keep up the great work! 🎉

---
PRAVIEL | Learning Ancient Languages
        """.strip()

        return subject, html, text

    @staticmethod
    def onboarding_day7(
        username: str,
        xp_earned: int,
        lessons_completed: int,
        streak_days: int,
        community_url: str,
    ) -> tuple[str, str, str]:
        """Day 7 onboarding email template.

        Args:
            username: User's username
            xp_earned: Total XP earned in first week
            lessons_completed: Number of lessons completed
            streak_days: Current streak
            community_url: URL to community/Discord

        Returns:
            Tuple of (subject, html_body, text_body)
        """
        subject = "You made it a week! Here's what's next 🎉"

        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            {EmailTemplates.get_base_style()}
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>First Week Complete! 🎉</h1>
                </div>
                <div class="content">
                    <p>Hi <strong>{username}</strong>,</p>

                    <p>Congratulations on completing your first week with PRAVIEL! Here's what you've accomplished:</p>

                    <table class="stats-table">
                        <tr>
                            <td>
                                <span class="stat-value">{xp_earned}</span>
                                <span class="stat-label">📊 XP Earned</span>
                            </td>
                            <td>
                                <span class="stat-value">{lessons_completed}</span>
                                <span class="stat-label">✅ Lessons</span>
                            </td>
                        </tr>
                        <tr>
                            <td colspan="2">
                                <span class="stat-value">{streak_days}</span>
                                <span class="stat-label">🔥 Day Streak</span>
                            </td>
                        </tr>
                    </table>

                    <div class="highlight-box">
                        <h3 style="margin-top: 0; color: #667eea;">🚀 What's Next?</h3>
                        <p><strong>Week 2 Goals:</strong></p>
                        <ul>
                            <li>Maintain your {streak_days}-day streak</li>
                            <li>Complete 5 more lessons</li>
                            <li>Review SRS cards daily</li>
                            <li>Read one authentic text passage</li>
                        </ul>
                    </div>

                    <div class="highlight-box">
                        <h3 style="margin-top: 0; color: #667eea;">👥 Join the Community</h3>
                        <p style="margin-bottom: 0;">Connect with other ancient language learners:</p>
                        <ul style="margin-bottom: 0;">
                            <li>Share your progress</li>
                            <li>Ask questions</li>
                            <li>Get motivation from others</li>
                            <li>Participate in challenges</li>
                        </ul>
                    </div>

                    <div style="text-align: center; margin: 30px 0;">
                        <a href="{community_url}" class="button">
                            Join Our Discord Community
                        </a>
                    </div>

                    <p style="text-align: center;">You're off to a great start. Keep going! 💪</p>
                </div>
                <div class="footer">
                    <p>PRAVIEL | Learning Ancient Languages</p>
                </div>
            </div>
        </body>
        </html>
        """

        text = f"""
First Week Complete! 🎉

Hi {username},

Congratulations on completing your first week with PRAVIEL! Here's what you've accomplished:

📊 XP Earned: {xp_earned}
✅ Lessons: {lessons_completed}
🔥 Streak: {streak_days} days

🚀 What's Next?
Week 2 Goals:
• Maintain your {streak_days}-day streak
• Complete 5 more lessons
• Review SRS cards daily
• Read one authentic text passage

👥 Join the Community
Connect with other ancient language learners:
• Share your progress
• Ask questions
• Get motivation from others
• Participate in challenges

Join our Discord: {community_url}

You're off to a great start. Keep going! 💪

---
PRAVIEL | Learning Ancient Languages
        """.strip()

        return subject, html, text

    # ========================================================================
    # RE-ENGAGEMENT CAMPAIGNS
    # ========================================================================

    @staticmethod
    def re_engagement_7days(
        username: str,
        last_language: str,
        last_lesson_name: str,
        quick_lesson_url: str,
    ) -> tuple[str, str, str]:
        """7-day inactive re-engagement email.

        Args:
            username: User's username
            last_language: Last language they were studying
            last_lesson_name: Name of last lesson
            quick_lesson_url: Direct link to continue

        Returns:
            Tuple of (subject, html_body, text_body)
        """
        subject = f"We miss you! Come back to your {last_language} studies"

        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            {EmailTemplates.get_base_style()}
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>We Miss You! 👋</h1>
                </div>
                <div class="content">
                    <p>Hi <strong>{username}</strong>,</p>

                    <p>It's been a week since your last lesson. Your {last_language} journey is waiting for you!</p>

                    <div class="highlight-box">
                        <p style="margin: 0;"><strong>Where you left off:</strong></p>
                        <p style="margin: 5px 0 0 0; color: #667eea; font-size: 16px;">{last_lesson_name}</p>
                    </div>

                    <p>Just <strong>5 minutes today</strong> will help you:</p>
                    <ul>
                        <li>Retain what you've already learned</li>
                        <li>Build momentum for tomorrow</li>
                        <li>Get back into your learning rhythm</li>
                    </ul>

                    <div style="text-align: center; margin: 30px 0;">
                        <a href="{quick_lesson_url}" class="button">
                            Pick Up Where You Left Off
                        </a>
                    </div>

                    <p style="color: #666; font-size: 14px; text-align: center;">
                        No pressure - whenever you're ready, we're here! 😊
                    </p>
                </div>
                <div class="footer">
                    <p>PRAVIEL | Learning Ancient Languages</p>
                </div>
            </div>
        </body>
        </html>
        """

        text = f"""
We Miss You! 👋

Hi {username},

It's been a week since your last lesson. Your {last_language} journey is waiting for you!

Where you left off: {last_lesson_name}

Just 5 minutes today will help you:
• Retain what you've already learned
• Build momentum for tomorrow
• Get back into your learning rhythm

Pick up where you left off: {quick_lesson_url}

No pressure - whenever you're ready, we're here! 😊

---
PRAVIEL | Learning Ancient Languages
        """.strip()

        return subject, html, text

    @staticmethod
    def re_engagement_14days(
        username: str,
        streak_lost: int,
        lessons_completed: int,
        welcome_back_url: str,
    ) -> tuple[str, str, str]:
        """14-day inactive re-engagement email.

        Args:
            username: User's username
            streak_lost: Streak they had before going inactive
            lessons_completed: Total lessons they completed
            welcome_back_url: Link with optional welcome back bonus

        Returns:
            Tuple of (subject, html_body, text_body)
        """
        subject = f"Your {streak_lost}-day streak is waiting for you"

        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            {EmailTemplates.get_base_style()}
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>Your Progress is Still Here! 💪</h1>
                </div>
                <div class="content">
                    <p>Hi <strong>{username}</strong>,</p>

                    <p>Remember your {streak_lost}-day streak? You worked hard to build that momentum.</p>

                    <div class="highlight-box" style="text-align: center;">
                        <p style="margin: 0; font-size: 16px;">You've already completed</p>
                        <span class="stat-value" style="font-size: 42px;">{lessons_completed}</span>
                        <span class="stat-label" style="font-size: 16px;">lessons</span>
                        <p style="margin: 10px 0 0 0; color: #666;">That's real progress!</p>
                    </div>

                    <p><strong>Starting again is easy:</strong></p>
                    <ul>
                        <li>Your progress is saved</li>
                        <li>All your learned vocabulary is still there</li>
                        <li>Just 5 minutes to get back in the flow</li>
                    </ul>

                    <div style="text-align: center; margin: 30px 0;">
                        <a href="{welcome_back_url}" class="button">
                            Welcome Back - Claim Your Bonus
                        </a>
                    </div>

                    <p style="color: #666; font-size: 14px; text-align: center;">
                        <strong>Special welcome back bonus:</strong> 2x XP for your first lesson! ⚡
                    </p>
                </div>
                <div class="footer">
                    <p>PRAVIEL | Learning Ancient Languages</p>
                </div>
            </div>
        </body>
        </html>
        """

        text = f"""
Your Progress is Still Here! 💪

Hi {username},

Remember your {streak_lost}-day streak? You worked hard to build that momentum.

You've already completed {lessons_completed} lessons - that's real progress!

Starting again is easy:
• Your progress is saved
• All your learned vocabulary is still there
• Just 5 minutes to get back in the flow

Welcome back - claim your bonus: {welcome_back_url}
Special welcome back bonus: 2x XP for your first lesson! ⚡

---
PRAVIEL | Learning Ancient Languages
        """.strip()

        return subject, html, text

    @staticmethod
    def re_engagement_30days(username: str, whats_new_url: str) -> tuple[str, str, str]:
        """30-day inactive re-engagement email.

        Args:
            username: User's username
            whats_new_url: Link to changelog/new features

        Returns:
            Tuple of (subject, html_body, text_body)
        """
        subject = "What's new since you left"

        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            {EmailTemplates.get_base_style()}
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>We've Been Busy! ✨</h1>
                </div>
                <div class="content">
                    <p>Hi <strong>{username}</strong>,</p>

                    <p>A lot has changed since your last visit. Here's what's new at PRAVIEL:</p>

                    <div class="highlight-box">
                        <h3 style="margin-top: 0; color: #667eea;">🆕 New Features</h3>
                        <ul style="margin-bottom: 0;">
                            <li><strong>5 New Languages</strong> - Now supporting 46 ancient languages</li>
                            <li><strong>Enhanced SRS</strong> - Smarter spaced repetition algorithm</li>
                            <li><strong>Social Features</strong> - Learn with friends, compete on leaderboards</li>
                            <li><strong>Daily Challenges</strong> - New themed challenges every day</li>
                        </ul>
                    </div>

                    <div class="highlight-box">
                        <h3 style="margin-top: 0; color: #667eea;">📚 New Content</h3>
                        <ul style="margin-bottom: 0;">
                            <li>20+ new authentic texts added</li>
                            <li>100+ new lessons across all languages</li>
                            <li>Improved pronunciation guides</li>
                        </ul>
                    </div>

                    <p>Want to start fresh? We've made it easier than ever to jump back in.</p>

                    <div style="text-align: center; margin: 30px 0;">
                        <a href="{whats_new_url}" class="button">
                            See What's New
                        </a>
                    </div>

                    <p style="text-align: center; color: #666;">Your account is still here, waiting for you! 😊</p>
                </div>
                <div class="footer">
                    <p>PRAVIEL | Learning Ancient Languages</p>
                </div>
            </div>
        </body>
        </html>
        """

        text = f"""
We've Been Busy! ✨

Hi {username},

A lot has changed since your last visit. Here's what's new at PRAVIEL:

🆕 New Features
• 5 New Languages - Now supporting 46 ancient languages
• Enhanced SRS - Smarter spaced repetition algorithm
• Social Features - Learn with friends, compete on leaderboards
• Daily Challenges - New themed challenges every day

📚 New Content
• 20+ new authentic texts added
• 100+ new lessons across all languages
• Improved pronunciation guides

Want to start fresh? We've made it easier than ever to jump back in.

See what's new: {whats_new_url}

Your account is still here, waiting for you! 😊

---
PRAVIEL | Learning Ancient Languages
        """.strip()

        return subject, html, text

    # ========================================================================
    # PASSWORD CHANGED NOTIFICATION
    # ========================================================================

    @staticmethod
    def password_changed(username: str, support_url: str) -> tuple[str, str, str]:
        """Password changed notification.

        Args:
            username: User's username
            support_url: Link to support if this wasn't them

        Returns:
            Tuple of (subject, html_body, text_body)
        """
        subject = "Your PRAVIEL password was changed"

        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            {EmailTemplates.get_base_style()}
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>Password Changed</h1>
                </div>
                <div class="content">
                    <p>Hi <strong>{username}</strong>,</p>

                    <p>This is a confirmation that your PRAVIEL account password was successfully changed.</p>

                    <div class="warning-box">
                        <strong>⚠️ If you didn't make this change:</strong><br>
                        Someone else may have accessed your account. Please secure your account immediately.
                    </div>

                    <p>If this wasn't you:</p>
                    <ol>
                        <li>Click the button below to reset your password</li>
                        <li>Enable two-factor authentication (if available)</li>
                        <li>Contact our support team</li>
                    </ol>

                    <div style="text-align: center; margin: 30px 0;">
                        <a href="{support_url}" class="button">
                            Secure My Account
                        </a>
                    </div>

                    <p>If you made this change, no action is needed.</p>
                </div>
                <div class="footer">
                    <p>PRAVIEL | Learning Ancient Languages<br>
                    Need help? Contact <a href="mailto:support@praviel.com">support@praviel.com</a></p>
                </div>
            </div>
        </body>
        </html>
        """

        text = f"""
Password Changed

Hi {username},

This is a confirmation that your PRAVIEL account password was successfully changed.

⚠️ If you didn't make this change:
Someone else may have accessed your account. Please secure your account immediately.

If this wasn't you:
1. Reset your password: {support_url}
2. Enable two-factor authentication (if available)
3. Contact our support team: support@praviel.com

If you made this change, no action is needed.

---
PRAVIEL | Learning Ancient Languages
        """.strip()

        return subject, html, text
