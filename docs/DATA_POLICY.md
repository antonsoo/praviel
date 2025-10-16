# AncientLanguages — Data Use & Privacy Policy

**Version:** 1.0
**Effective Date:** 2025-10-16

> **Scope**: This Privacy Policy describes how AncientLanguages ("we," "us," "our") collects, uses, shares, and protects personal information when you use the AncientLanguages application (desktop, web, and mobile versions). For financial support data, see [Privacy Policy (Donations & Memberships)](PRIVACY.md). For general app terms, see [Terms of Use](TERMS_OF_USE.md).

---

## 1. Data Controller

**Data Controller**: Anton Soloviev (sole proprietor), doing business as "AncientLanguages"
**Email**: antonnsoloviev@gmail.com
**Location**: United States
**GitHub Issues**: https://github.com/antonsoo/AncientLanguages/issues (for non-sensitive matters)

---

## 2. Information We Collect

### 2.1 Information You Provide Directly

#### Optional Account Information
- **Email address**: If you create an account (optional)
- **Display name/username**: Optional profile customization
- **Password**: Securely hashed (never stored in plain text)

#### User-Generated Content
- **Lesson requests**: Language selections, proficiency levels, exercise types
- **Chat messages**: Conversations with AI tutors (when using chat feature)
- **Reader selections**: Text passages you view or generate lessons from
- **Custom word lists**: If you create personal vocabulary lists (future feature)

#### BYOK (Bring Your Own Key) Data
- **API keys**: OpenAI, Anthropic, Google Gemini, ElevenLabs API keys (if provided)
  - **Storage**: Encrypted locally on your device or in encrypted cloud storage (if account sync enabled)
  - **Transmission**: Sent directly to the respective AI provider's API (we do not intercept or store them on our servers)
- **Provider selection**: Which AI provider you choose for lessons/chat/TTS

### 2.2 Information Collected Automatically

#### App Usage Data
- **Lesson history**: Completed lessons, scores, timestamps
- **Exercise interactions**: Answers, hints used, time spent per task
- **Feature usage**: Which app features you use (lessons, chat, reader), frequency
- **Session data**: App launch/close times, session duration

#### Device & Technical Information
- **Device type**: Desktop, mobile, web browser
- **Operating system**: Windows, macOS, Linux, Android, iOS
- **App version**: AncientLanguages version number
- **Screen resolution**: For responsive UI (does not identify individuals)
- **Language/locale settings**: To personalize content

#### Error & Diagnostic Data
- **Crash reports**: Stack traces, error messages (anonymized)
- **Performance metrics**: App load times, API response times
- **Network connectivity**: Online/offline status (for caching optimization)

### 2.3 Analytics & Cookies (Web Version)

#### Analytics Tools (Future Implementation)
- We may use privacy-focused analytics (e.g., Plausible, Umami) to understand aggregate usage patterns
- **No personally identifiable information** is sent to analytics tools
- **No cross-site tracking** or advertising trackers

#### Cookies (Web Only)
- **Essential cookies**: Session management, login persistence
- **Functional cookies**: User preferences (theme, language), terms acceptance status
- **No advertising or tracking cookies**

**Cookie control**: You can disable cookies in your browser settings, but this may limit app functionality (e.g., you'll need to log in each time).

### 2.4 Information from Third Parties

#### AI Providers (When Using BYOK)
- When you use OpenAI, Anthropic, or Google with your API key, those providers process your lesson/chat content
- We do **not** receive your conversations back from those providers (they're processed on their servers)
- Your interactions are subject to their privacy policies:
  - OpenAI: https://openai.com/privacy
  - Anthropic: https://www.anthropic.com/privacy
  - Google: https://policies.google.com/privacy

#### OAuth Authentication (Future Feature)
- If we add "Sign in with Google/GitHub," those providers will share basic profile info (email, name) with your consent

---

## 3. How We Use Your Information

### 3.1 Core App Functionality
- **Provide lessons**: Generate and deliver language exercises
- **Save progress**: Store lesson history and scores (if account created)
- **Personalize experience**: Adjust difficulty based on past performance
- **Reader features**: Provide morphological analysis, dictionary lookups
- **Chat tutoring**: Enable AI-powered conversational practice

### 3.2 Account Management
- **Authentication**: Verify your identity when logging in
- **Password reset**: Send password reset links (if account created)
- **Sync across devices**: (Future) sync preferences and history across platforms

### 3.3 App Improvement
- **Bug fixes**: Diagnose and resolve technical issues
- **Feature development**: Understand which features are popular, which need improvement
- **Performance optimization**: Identify slow APIs or bottlenecks
- **A/B testing**: (Future) test new UX designs with user consent

### 3.4 Communication
- **Service updates**: Notify you of app updates, new features
- **Security alerts**: Inform you of suspicious account activity
- **Support responses**: Respond to your questions or feedback
- **Marketing (opt-in only)**: Send newsletters about new languages, features (you can unsubscribe anytime)

### 3.5 Legal & Safety
- **Comply with laws**: Respond to legal requests (subpoenas, warrants)
- **Prevent abuse**: Detect and prevent fraud, spam, or malicious activity
- **Enforce terms**: Investigate violations of Terms of Use

---

## 4. Legal Bases for Processing (GDPR/UK GDPR)

If you are in the EU/UK/EEA, we process your data based on:

| Purpose | Legal Basis |
|---------|-------------|
| Provide core app features | **Contractual necessity** (to perform our Terms of Use) |
| Save lesson history, account data | **Contractual necessity** + **Legitimate interests** (improve service) |
| Send service updates, security alerts | **Legitimate interests** (keep users informed, secure accounts) |
| Marketing emails (opt-in) | **Consent** (you can withdraw anytime) |
| Comply with legal obligations | **Legal obligation** (e.g., respond to court orders) |
| Analytics, bug tracking | **Legitimate interests** (improve app, fix bugs) |

---

## 5. How We Share Your Information

### 5.1 We Do NOT Sell Your Data
We do **not** sell, rent, or trade your personal information to third parties for marketing purposes.

### 5.2 Service Providers & Processors

We share data with trusted third parties who help us operate the App:

| Provider Type | Purpose | Data Shared | Safeguards |
|---------------|---------|-------------|------------|
| **Cloud hosting** | Host backend servers, database | All app data (encrypted at rest) | AWS, Google Cloud, or similar (SOC 2 compliant) |
| **AI providers** | Generate lessons, chat responses | Your lesson requests, chat messages (if using BYOK) | Data sent directly to OpenAI/Anthropic/Google; subject to their DPAs |
| **Email service** | Send password resets, updates | Email address only | SendGrid, Mailgun, or similar (GDPR-compliant) |
| **Analytics** | (Future) Understand usage patterns | Anonymized, aggregated data | Plausible, Umami (privacy-focused, GDPR-compliant) |
| **Error tracking** | (Future) Diagnose crashes | Error logs (no PII) | Sentry (GDPR-compliant) |

**Data Processing Agreements (DPAs)**: We require all processors to sign DPAs ensuring GDPR/CCPA compliance.

### 5.3 Third-Party AI Providers (BYOK Mode)

When you use your own API keys:
- **Direct transmission**: Your lesson/chat content goes directly to the AI provider (OpenAI, Anthropic, Google)
- **We do not intercept or store** the responses on our servers (except for caching temporary results in your session)
- **Privacy policies apply**: Your data is subject to the provider's privacy policy (see Section 2.4)

**Important**: If you're concerned about privacy, use the "echo" provider (rule-based, no AI, no external API calls).

### 5.4 Legal Requirements

We may disclose your information if required by law:
- **Subpoenas, court orders, legal process**
- **National security or law enforcement requests** (we will notify you unless prohibited)
- **Compliance with GDPR, CCPA, or other data protection laws**

We will challenge overly broad or unlawful requests to the extent permitted by law.

### 5.5 Business Transfers

If AncientLanguages is acquired, merged, or sells assets, your data may be transferred to the successor entity. You will be notified via email or app notification, and the new entity must honor this Privacy Policy (or obtain your consent to changes).

---

## 6. Data Retention

| Data Type | Retention Period | Reason |
|-----------|------------------|--------|
| **Account data** (email, profile) | Until account deletion | Provide ongoing service |
| **Lesson history** | 7 years or until deletion | Track progress, improve lessons |
| **Chat logs** | 30 days (cached), then deleted | Temporary for context; not stored long-term |
| **Reader activity** | Not tracked (unless you generate lessons) | Privacy by design |
| **Error logs** | 90 days | Debugging, then auto-deleted |
| **Analytics data** | Aggregated indefinitely (no PII) | Understand long-term trends |
| **BYOK API keys** | Never stored on our servers; encrypted locally | Security |

**Account deletion**: If you delete your account, we will delete your personal data within **30 days**, except where retention is required by law (e.g., financial records for tax purposes, retained for 7 years).

**Backups**: Deleted data may persist in encrypted backups for up to **90 days** before permanent deletion.

---

## 7. International Data Transfers

### 7.1 Data Storage Location
- **Primary servers**: United States (AWS, Google Cloud, or similar)
- **Backups**: May be replicated to EU/US data centers (encrypted)

### 7.2 Transfers Outside the EEA (for EU/UK users)
If you are in the EU/UK/EEA, your data may be transferred to the U.S. We rely on:
- **Standard Contractual Clauses (SCCs)**: EU-approved data transfer mechanisms
- **Adequacy decisions**: (If applicable, e.g., EU-US Data Privacy Framework)
- **Processor safeguards**: Our cloud providers (AWS, Google Cloud) comply with GDPR

---

## 8. Data Security

### 8.1 Technical Measures
- **Encryption at rest**: All database data encrypted (AES-256)
- **Encryption in transit**: HTTPS/TLS for all API calls
- **Password hashing**: Passwords stored with bcrypt or Argon2 (never plain text)
- **API key encryption**: BYOK keys encrypted locally on your device (AES-256)
- **Access controls**: Role-based access; only authorized personnel can access servers

### 8.2 Organizational Measures
- **Limited access**: Only necessary personnel have access to user data
- **Audit logs**: Server access is logged for security reviews
- **Security updates**: Regular patching of software dependencies
- **Incident response**: Plan in place for data breaches (see Section 9)

### 8.3 No Absolute Security
**Disclaimer**: No method of transmission or storage is 100% secure. We cannot guarantee absolute security but use industry-standard best practices.

---

## 9. Data Breach Notification

If we discover a data breach affecting your personal information:
1. **EU/UK users**: We will notify you within **72 hours** (as required by GDPR)
2. **California users**: We will notify you "without unreasonable delay" (as required by CCPA)
3. **All users**: We will notify affected users via email and/or app notification

**What we'll tell you**:
- Nature of the breach (what data was compromised)
- Steps we're taking to mitigate harm
- Steps you can take to protect yourself (e.g., change password)

---

## 10. Your Rights & Choices

### 10.1 Access & Portability (GDPR Article 15, CCPA)
- **Right to access**: Request a copy of your personal data
- **Right to portability**: Receive your data in a machine-readable format (JSON/CSV)
- **How to request**: Email antonnsoloviev@gmail.com with subject "Data Access Request"

### 10.2 Correction (GDPR Article 16, CCPA)
- **Right to rectification**: Correct inaccurate or incomplete data
- **How**: Update your profile in the App, or email us

### 10.3 Deletion (GDPR Article 17, CCPA)
- **Right to erasure**: Request deletion of your account and data
- **How**: Go to Profile → Settings → Delete Account, or email us
- **Exceptions**: We may retain data if required by law (e.g., tax records)

### 10.4 Objection & Restriction (GDPR Articles 18, 21)
- **Right to object**: Object to processing based on legitimate interests (e.g., analytics)
- **Right to restriction**: Request limited processing (e.g., only store, don't use)
- **How**: Email antonnsoloviev@gmail.com with your request

### 10.5 Withdraw Consent (GDPR Article 7)
- **Marketing emails**: Unsubscribe link in every email
- **Analytics**: (Future) Opt-out in App settings
- **Account**: Delete account to withdraw all consents

### 10.6 Do Not Sell My Personal Information (CCPA)
- **We do not sell personal information** (as defined by CCPA)
- If this changes, we will provide an opt-out mechanism

### 10.7 Lodge a Complaint (GDPR Article 77)
- **EU/UK users**: You have the right to lodge a complaint with your local data protection authority
- **List of authorities**: https://edpb.europa.eu/about-edpb/board/members_en

---

## 11. Children's Privacy (COPPA Compliance)

### 11.1 Age Restriction
- The App is intended for users **13 years and older**
- We do not knowingly collect personal information from children under 13 without verifiable parental consent

### 11.2 Parental Rights
If you are a parent/guardian and believe your child (under 13) has provided personal information:
- **Review**: Request to see what data we have
- **Delete**: Request deletion of your child's data
- **Stop collection**: Opt your child out of further data collection
- **How**: Email antonnsoloviev@gmail.com with subject "COPPA Request"

### 11.3 Verification
For COPPA requests, we may require verification of parental status (e.g., signed consent form, credit card verification).

---

## 12. California Privacy Rights (CCPA/CPRA)

If you are a California resident, you have additional rights under the California Consumer Privacy Act (CCPA):

### 12.1 Right to Know (CCPA §1798.100)
- What personal information we collect
- Sources of that information
- Purposes for collection
- Third parties we share with

### 12.2 Right to Delete (CCPA §1798.105)
- Request deletion of your personal information (with exceptions)

### 12.3 Right to Non-Discrimination (CCPA §1798.125)
- We will not discriminate against you for exercising your CCPA rights

### 12.4 How to Exercise Rights
- **Email**: antonnsoloviev@gmail.com with subject "CCPA Request"
- **Response time**: Within 45 days (extendable to 90 days if complex)
- **Verification**: We may ask for confirmation of your identity (e.g., email verification)

### 12.5 Authorized Agent
You may designate an authorized agent to make requests on your behalf. The agent must provide proof of authorization.

---

## 13. European User Rights (GDPR Summary)

If you are in the EU/UK/EEA, you have these rights:

| Right | Description | How to Exercise |
|-------|-------------|-----------------|
| **Access** (Art. 15) | Get a copy of your data | Email us |
| **Rectification** (Art. 16) | Correct inaccurate data | Update in app or email us |
| **Erasure** (Art. 17) | Delete your data ("right to be forgotten") | Delete account or email us |
| **Restriction** (Art. 18) | Limit how we process your data | Email us |
| **Portability** (Art. 20) | Get your data in machine-readable format | Email us |
| **Objection** (Art. 21) | Object to processing (e.g., marketing, analytics) | Email us or adjust app settings |
| **Withdraw consent** (Art. 7) | Revoke any consent you gave | Unsubscribe from emails, delete account |
| **Lodge complaint** (Art. 77) | Complain to data protection authority | Contact your local DPA |

**Response time**: Within **1 month** (extendable to 3 months if complex).

---

## 14. Cookies & Tracking (Web Version)

### 14.1 What Cookies We Use

| Cookie Type | Purpose | Duration | Can You Disable It? |
|-------------|---------|----------|---------------------|
| **Essential** | Session management, login | Session or 30 days | No (required for app to work) |
| **Functional** | Save preferences (theme, language) | 1 year | Yes (but you'll lose preferences) |
| **Analytics** | (Future) Aggregated usage stats | Session | Yes (opt-out in settings) |

### 14.2 Third-Party Cookies
- **We do not use** advertising or tracking cookies (Google Analytics, Facebook Pixel, etc.)
- If we add analytics in the future, we will use privacy-focused tools (Plausible, Umami) that do not set tracking cookies

### 14.3 Cookie Control
- **Browser settings**: You can block cookies entirely (may break login)
- **App settings**: (Future) Toggle analytics cookies on/off

---

## 15. Changes to This Privacy Policy

### 15.1 Updates
- We may update this Privacy Policy from time to time
- **Material changes** will be communicated via:
  - App notification banner
  - Email (if you have an account)
  - Updated "Effective Date" at the top of this document

### 15.2 Your Options
- **Continue using the App**: Constitutes acceptance of the new policy
- **Delete your account**: If you disagree with changes, you can delete your account

---

## 16. Contact Us

### 16.1 Privacy Questions
**Email**: antonnsoloviev@gmail.com
**Subject**: "Privacy Question"

### 16.2 Data Subject Requests
**Email**: antonnsoloviev@gmail.com
**Subject**: "Data Request" (specify: Access, Deletion, Correction, CCPA, GDPR, COPPA)

### 16.3 Non-Sensitive Issues
**GitHub**: https://github.com/antonsoo/AncientLanguages/issues

### 16.4 EU Representative (If Required by GDPR)
*(To be added if user base in EU exceeds thresholds requiring formal representation)*

---

## 17. Additional Resources

- **Terms of Use**: [TERMS_OF_USE.md](TERMS_OF_USE.md)
- **Text License Agreement**: [TEXT_LICENSE_AGREEMENT.md](TEXT_LICENSE_AGREEMENT.md)
- **Supporter Terms (Donations)**: [TERMS.md](TERMS.md)
- **Supporter Privacy (Donations)**: [PRIVACY.md](PRIVACY.md)
- **GDPR Portal**: https://gdpr.eu/ (for EU users)
- **CCPA Portal**: https://oag.ca.gov/privacy/ccpa (for California users)
- **COPPA Portal**: https://www.ftc.gov/enforcement/rules/rulemaking-regulatory-reform-proceedings/childrens-online-privacy-protection-rule (for parents)

---

## 18. Acknowledgment

By using the AncientLanguages App, you acknowledge that you have read and understood this Privacy Policy and consent to the collection, use, and sharing of your information as described herein.

---

**Last Updated**: 2025-10-16
**Version**: 1.0

© 2025 Anton Soloviev. All rights reserved.
