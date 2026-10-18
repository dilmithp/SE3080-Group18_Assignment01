import os
import subprocess

html_content = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>CareConnect - Complete Product & Architecture Guide</title>
<style>
  @page {
    size: A4;
    margin: 18mm 15mm 18mm 15mm;
    @bottom-right {
      content: counter(page);
    }
  }

  body {
    font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, Roboto, Helvetica, Arial, sans-serif;
    color: #1e293b;
    line-height: 1.6;
    margin: 0;
    padding: 0;
    font-size: 10.5pt;
    background-color: #ffffff;
  }

  .cover {
    page-break-after: always;
    text-align: center;
    padding-top: 70px;
    padding-bottom: 50px;
  }

  .badge {
    display: inline-block;
    padding: 6px 16px;
    font-size: 12px;
    font-weight: 700;
    letter-spacing: 1px;
    text-transform: uppercase;
    background-color: #e0e7ff;
    color: #4338ca;
    border-radius: 9999px;
    margin-bottom: 24px;
  }

  .cover h1 {
    font-size: 34pt;
    color: #0f172a;
    margin-bottom: 10px;
    font-weight: 800;
    letter-spacing: -0.5px;
  }

  .cover .subtitle {
    font-size: 15pt;
    color: #475569;
    max-width: 620px;
    margin: 0 auto 30px auto;
    font-weight: 400;
  }

  .cover .divider {
    width: 80px;
    height: 4px;
    background: linear-gradient(90deg, #4f46e5, #06b6d4);
    margin: 25px auto;
    border-radius: 2px;
  }

  .meta-box {
    margin: 35px auto;
    max-width: 520px;
    background-color: #f8fafc;
    border: 1px solid #e2e8f0;
    border-radius: 12px;
    padding: 20px 25px;
    text-align: left;
    box-shadow: 0 2px 4px rgba(0,0,0,0.02);
  }

  .meta-row {
    display: flex;
    justify-content: space-between;
    padding: 7px 0;
    border-bottom: 1px dashed #cbd5e1;
    font-size: 10.5pt;
  }

  .meta-row:last-child {
    border-bottom: none;
  }

  .meta-label {
    font-weight: 600;
    color: #64748b;
  }

  .meta-value {
    font-weight: 700;
    color: #0f172a;
  }

  h2 {
    font-size: 17pt;
    color: #1e1b4b;
    border-bottom: 2px solid #e2e8f0;
    padding-bottom: 6px;
    margin-top: 28px;
    margin-bottom: 14px;
    page-break-after: avoid;
  }

  h3 {
    font-size: 12.5pt;
    color: #312e81;
    margin-top: 20px;
    margin-bottom: 8px;
    page-break-after: avoid;
  }

  p {
    margin-bottom: 11px;
    text-align: justify;
  }

  ul, ol {
    margin-top: 6px;
    margin-bottom: 14px;
    padding-left: 22px;
  }

  li {
    margin-bottom: 5px;
  }

  .callout {
    background-color: #f0fdf4;
    border-left: 4px solid #16a34a;
    padding: 12px 16px;
    border-radius: 0 8px 8px 0;
    margin: 16px 0;
  }

  .callout-info {
    background-color: #eff6ff;
    border-left: 4px solid #2563eb;
    padding: 12px 16px;
    border-radius: 0 8px 8px 0;
    margin: 16px 0;
  }

  .callout-purple {
    background-color: #faf5ff;
    border-left: 4px solid #9333ea;
    padding: 12px 16px;
    border-radius: 0 8px 8px 0;
    margin: 16px 0;
  }

  .card-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 12px;
    margin: 15px 0;
  }

  .card {
    border: 1px solid #e2e8f0;
    background-color: #f8fafc;
    border-radius: 8px;
    padding: 12px 14px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.03);
  }

  .card h4 {
    margin: 0 0 6px 0;
    color: #1e293b;
    font-size: 11pt;
  }

  table {
    width: 100%;
    border-collapse: collapse;
    margin: 16px 0;
    font-size: 9.5pt;
  }

  table, th, td {
    border: 1px solid #cbd5e1;
  }

  th {
    background-color: #f1f5f9;
    color: #0f172a;
    text-align: left;
    padding: 8px 10px;
    font-weight: 700;
  }

  td {
    padding: 7px 10px;
    vertical-align: top;
  }

  tr:nth-child(even) td {
    background-color: #f8fafc;
  }

  code {
    background-color: #f1f5f9;
    padding: 2px 5px;
    border-radius: 4px;
    font-family: Consolas, monospace;
    font-size: 9pt;
    color: #b91c1c;
  }

  pre {
    background-color: #0f172a;
    color: #f8fafc;
    padding: 12px;
    border-radius: 6px;
    font-family: Consolas, monospace;
    font-size: 8.5pt;
    overflow-x: auto;
    margin: 12px 0;
  }

  .step-container {
    margin: 15px 0;
  }

  .step-box {
    display: flex;
    margin-bottom: 12px;
    align-items: flex-start;
  }

  .step-number {
    background: #4f46e5;
    color: #ffffff;
    font-weight: 700;
    border-radius: 50%;
    width: 26px;
    height: 26px;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    font-size: 10pt;
    flex-shrink: 0;
    margin-right: 12px;
    margin-top: 2px;
  }

  .step-content {
    flex: 1;
  }

  .step-title {
    font-weight: 700;
    color: #1e293b;
    margin-bottom: 2px;
  }

  .page-break {
    page-break-before: always;
  }
</style>
</head>
<body>

<!-- COVER PAGE -->
<div class="cover">
  <div class="badge">Comprehensive Product Guide</div>
  <h1>CareConnect</h1>
  <div class="subtitle">Elderly Companionship & Micro-Volunteering Mobile Platform</div>
  <div class="divider"></div>
  <p style="text-align: center; max-width: 550px; margin: 0 auto 30px auto; color: #64748b;">
    An end-to-end guide detailing the real-world problem, user experience, core features, technical architecture, and system operation from a zero-knowledge perspective.
  </p>

  <div class="meta-box">
    <div class="meta-row">
      <span class="meta-label">Application Type:</span>
      <span class="meta-value">Cross-Platform Mobile & Web App</span>
    </div>
    <div class="meta-row">
      <span class="meta-label">Frontend Framework:</span>
      <span class="meta-value">Flutter 3.x (Dart, Null-Safe)</span>
    </div>
    <div class="meta-row">
      <span class="meta-label">Backend Infrastructure:</span>
      <span class="meta-value">Google Firebase (Firestore, Auth, Storage, Cloud Functions)</span>
    </div>
    <div class="meta-row">
      <span class="meta-label">Architecture:</span>
      <span class="meta-value">Feature-First Clean Architecture + Riverpod</span>
    </div>
    <div class="meta-row">
      <span class="meta-label">Key Pillars:</span>
      <span class="meta-value">Companionship, Safety, Accessibility, Trust</span>
    </div>
  </div>

  <div style="margin-top: 60px; font-size: 9.5pt; color: #94a3b8;">
    CareConnect Engineering & Product Documentation
  </div>
</div>

<!-- SECTION 1 -->
<h2>1. What is CareConnect? (Executive Summary)</h2>
<p>
  <strong>CareConnect</strong> is a modern mobile platform that connects <strong>senior citizens</strong> with <strong>verified community volunteers</strong> for companionship and small everyday help.
</p>
<p>
  Think of CareConnect as an <em>"Uber-style on-demand network for informal social support and micro-volunteering"</em>.
  Instead of requiring long-term volunteer contracts, it empowers local youth, students, and community members to offer <strong>short, flexible sessions (30 to 60 minutes)</strong> to help elderly neighbors with non-medical everyday tasks.
</p>

<div class="card-grid">
  <div class="card">
    <h4>🤝 Genuine Companionship</h4>
    <p style="margin: 0; font-size: 9pt; color: #475569;">
      Engaging in friendly conversations, playing chess, sharing stories, drinking tea, and reducing social isolation and depression.
    </p>
  </div>
  <div class="card">
    <h4>🛒 Light Everyday Errands</h4>
    <p style="margin: 0; font-size: 9pt; color: #475569;">
      Grocery pickup, accompaniment on neighborhood walks, carrying heavy items, or visiting the local pharmacy.
    </p>
  </div>
  <div class="card">
    <h4>📱 Basic Tech Assistance</h4>
    <p style="margin: 0; font-size: 9pt; color: #475569;">
      Helping seniors make video calls to overseas relatives, paying utility bills online, or operating smartphones.
    </p>
  </div>
  <div class="card">
    <h4>🛡️ Trust, Safety & Verification</h4>
    <p style="margin: 0; font-size: 9pt; color: #475569;">
      Government ID checks, admin approvals, post-session ratings, and automated trust scores to protect seniors.
    </p>
  </div>
</div>

<div class="callout-info">
  <strong>Key Distinction:</strong>
  CareConnect is <em>not</em> an emergency hospital service or an expensive nursing agency.
  It is a safe, community-driven micro-volunteering platform that bridges generational gaps and keeps senior citizens actively engaged and cared for within their local neighborhood.
</div>

<!-- SECTION 2 -->
<h2>2. The Real-World Problem It Solves</h2>
<p>
  Understanding the motivation behind CareConnect will help you explain the application confidently:
</p>

<ol>
  <li>
    <strong>The Global Aging & Loneliness Crisis:</strong>
    As younger generations relocate for jobs and education, millions of elderly people live by themselves. Medical research shows chronic loneliness has the health impact of smoking 15 cigarettes a day. Most seniors do not require intensive clinical medical nursing; what they lack is social connection and light day-to-day assistance.
  </li>
  <li>
    <strong>Barriers in Traditional Volunteering:</strong>
    Students and young professionals genuinely want to give back to their communities, but conventional NGO programs demand rigid weekly schedules or multi-month commitments. CareConnect introduces <em>micro-volunteering</em>: volunteering in bite-sized, 30–60 minute increments whenever the volunteer has free time.
  </li>
  <li>
    <strong>The Safety and Stranger Barrier:</strong>
    Elderly people and their families are often hesitant to invite strangers into their homes. CareConnect removes this anxiety through <strong>mandatory ID document uploads</strong>, <strong>admin vetting</strong>, and an <strong>algorithmic Trust Score</strong> that reflects reliable past visits.
  </li>
  <li>
    <strong>Digital Inaccessibility for Seniors:</strong>
    Most modern mobile applications are designed for tech-savvy youngsters, featuring small fonts, low-contrast subtle colors, and complex gestures. CareConnect is engineered <strong>accessibility-first</strong>, offering dynamic large text, high contrast, and simplified interfaces tailored for elderly eyes and hands.
  </li>
</ol>

<div class="page-break"></div>

<!-- SECTION 3 -->
<h2>3. The Complete User Journey (The Core Loop)</h2>
<p>
  Here is the lifecycle of how a user interacts with CareConnect from registration to completed session:
</p>

<div class="step-container">
  <div class="step-box">
    <div class="step-number">1</div>
    <div class="step-content">
      <div class="step-title">Account Creation & Role Selection</div>
      The user registers via email/password or passwordless magic link and selects their role:
      <strong>Elderly</strong> (seeking companionship or help) or <strong>Volunteer</strong> (offering time and skills).
    </div>
  </div>

  <div class="step-box">
    <div class="step-number">2</div>
    <div class="step-content">
      <div class="step-title">Profile Setup & Accessibility Customization</div>
      Users set their locality, bio, skills/needs, and spoken languages (e.g. English, Sinhala, Tamil). Seniors can configure their <strong>Emergency Contact</strong> and adjust display settings (large font scale, high contrast mode).
    </div>
  </div>

  <div class="step-box">
    <div class="step-number">3</div>
    <div class="step-content">
      <div class="step-title">Identity Verification</div>
      Volunteers submit an official identification document (National Identity Card, Passport, or Student ID). An Administrator reviews the document in the <strong>Admin Verification Queue</strong> and grants a verified badge.
    </div>
  </div>

  <div class="step-box">
    <div class="step-number">4</div>
    <div class="step-content">
      <div class="step-title">Smart Matching & Volunteer Discovery</div>
      The elderly user browses matched companions. The <strong>Matching Engine</strong> evaluates candidates based on proximity, required task overlap, availability times, and trust scores.
    </div>
  </div>

  <div class="step-box">
    <div class="step-number">5</div>
    <div class="step-content">
      <div class="step-title">Session Scheduling & Booking</div>
      The senior requests a session (single appointment or weekly recurring series). The platform runs automatic <em>conflict detection</em> so no volunteer is double-booked. The volunteer reviews and confirms.
    </div>
  </div>

  <div class="step-box">
    <div class="step-number">6</div>
    <div class="step-content">
      <div class="step-title">In-App Chat & Meetup</div>
      Ahead of the visit, the senior and volunteer can chat via secure in-app messaging. If the senior ever feels unsafe or unwell, the Emergency Contact button provides instant 1-tap phone dialing.
    </div>
  </div>

  <div class="step-box">
    <div class="step-number">7</div>
    <div class="step-content">
      <div class="step-title">Session Completion, Rating & Trust Score Update</div>
      Once the session finishes, it is marked as completed. The senior provides a 1–5 star rating and written review. In the background, a <strong>Firebase Cloud Function</strong> automatically recalculates the volunteer's public Trust Score.
    </div>
  </div>
</div>

<div class="callout">
  <strong>The 5-Word Formula:</strong> Post Need &rarr; Match &rarr; Book &rarr; Chat & Meet &rarr; Rate & Build Trust.
</div>

<!-- SECTION 4 -->
<h2>4. Detailed Screen & Feature Breakdown</h2>
<p>
  CareConnect is organized into distinct, specialized functional areas:
</p>

<h3>1. Authentication & Security (<code>auth_trust</code>)</h3>
<ul>
  <li><strong>Login & Registration:</strong> Supports standard email/password authentication as well as passwordless email-link sign-in for seniors who struggle with complex passwords.</li>
  <li><strong>Role-Based Access Control (RBAC):</strong> Three distinct roles (<code>elderly</code>, <code>volunteer</code>, <code>admin</code>), strictly enforced by Cloud Firestore security rules.</li>
  <li><strong>Admin Verification Queue:</strong> Administrators have a dedicated review portal where they inspect pending identity documents, view user details, and approve or reject verification requests.</li>
</ul>

<h3>2. User Profiles & Safety (<code>profiles</code>)</h3>
<ul>
  <li><strong>Profile Details:</strong> Displays avatar, bio, locality, languages spoken, skills offered, and help needed.</li>
  <li><strong>Emergency Contact Card:</strong> Prominently displays the senior's family contact name and phone number with a direct 1-tap phone dialer (<code>tel:</code> protocol) for immediate help.</li>
  <li><strong>Location Picker:</strong> Allows setting accurate home locality for distance-based matching.</li>
  <li><strong>Profile Completeness Indicator:</strong> Guides new users to fill in all essential safety and preference details.</li>
</ul>

<h3>3. Senior Accessibility Framework (<code>core/theme</code> & <code>profiles</code>)</h3>
<ul>
  <li><strong>Dynamic Text Scaling:</strong> An interactive slider that adjusts font sizes across every screen (up to 1.6x large text) so seniors with poor vision can read comfortably without squinting.</li>
  <li><strong>High Contrast Mode:</strong> Enhances borders, increases contrast ratios, and darkens text backgrounds for users with cataracts or low vision.</li>
  <li><strong>Simplified Interface Mode:</strong> Hides secondary buttons, complex menus, and background decorations to prevent confusion.</li>
  <li><strong>Motion Reduction:</strong> Replaces sliding transitions with gentle cuts to accommodate users sensitive to animations.</li>
</ul>

<div class="page-break"></div>

<h3>4. Smart Matching Engine (<code>matching</code>)</h3>
<ul>
  <li><strong>Locality & Distance Search:</strong> Locates nearby volunteers within a specified neighborhood or radius.</li>
  <li><strong>Multi-Factor Matching Algorithm:</strong> Evaluates compatibility based on:
    <ol>
      <li><strong>Distance / Locality Match:</strong> Closer volunteers score higher.</li>
      <li><strong>Skill Overlap:</strong> Matching tasks needed (e.g. "Tech Support", "Grocery Run") with volunteer capabilities.</li>
      <li><strong>Availability Windows:</strong> Matching free days and hours.</li>
      <li><strong>Spoken Language:</strong> Ensuring senior and volunteer can communicate fluently.</li>
      <li><strong>Trust Score Weight:</strong> Higher-rated, verified volunteers are recommended first.</li>
    </ol>
  </li>
  <li><strong>Match Details View:</strong> Displays complete match breakdown, reviews, and a direct button to schedule a visit.</li>
</ul>

<h3>5. Scheduling, Sessions & Recurring Bookings (<code>scheduling</code>)</h3>
<ul>
  <li><strong>Session Lifecycle:</strong> Structured state transitions: <code>requested</code> &rarr; <code>confirmed</code> &rarr; <code>completed</code> (or <code>cancelled</code>).</li>
  <li><strong>Recurring Weekly Series:</strong> Enables booking ongoing visits (e.g., "Every Tuesday at 10:00 AM for a walk").</li>
  <li><strong>Schedule Conflict Prevention:</strong> Checks existing appointments and rejects overlapping booking attempts.</li>
  <li><strong>Session Details Screen:</strong> Displays meeting location, special instructions, volunteer contact, and session status.</li>
</ul>

<h3>6. Trust Score & Feedback Loop (<code>auth_trust</code> & <code>scheduling</code>)</h3>
<ul>
  <li><strong>Post-Session Star Rating:</strong> Seniors evaluate completed sessions with 1 to 5 stars and optional comments.</li>
  <li><strong>Duplicate Rating Prevention:</strong> Guarantees each session is rated only once by each participant.</li>
  <li><strong>Automated Cloud Calculation:</strong> A Firebase Cloud Function computes the overall score using verified status, completed session count, and average rating.</li>
</ul>

<h3>7. In-App Messaging & Conversations (<code>messaging</code>)</h3>
<ul>
  <li><strong>1-on-1 Real-Time Chat:</strong> Direct messaging between senior and matched volunteer to confirm arrival times and meeting details.</li>
  <li><strong>Privacy Protection:</strong> Eliminates the need to exchange private phone numbers or WhatsApp contacts before establishing trust.</li>
</ul>

<h3>8. Community Feed (<code>community</code>)</h3>
<ul>
  <li><strong>Neighborhood Mutual Aid Board:</strong> A community feed where members can post public thank-yous, community announcements, and neighborhood requests.</li>
</ul>

<h3>9. In-App Notifications (<code>notifications</code>)</h3>
<ul>
  <li><strong>Notification Center:</strong> Displays immediate alerts for session requests, booking confirmations, new messages, and ID verification status updates.</li>
</ul>

<!-- SECTION 5 -->
<h2>5. Technical Architecture & Engineering Design</h2>
<p>
  CareConnect is architected following industry-standard <strong>Clean Architecture</strong>, the <strong>SOLID principles</strong>, and <strong>Riverpod state management</strong>.
</p>

<h3>Three-Layer Clean Architecture</h3>
<p>Each feature in <code>lib/features/</code> is strictly divided into three layers:</p>

<div class="card-grid">
  <div class="card">
    <h4>1. Data Layer (<code>data/</code>)</h4>
    <p style="font-size: 9pt; color: #475569; margin: 0;">
      Contains Freezed DTO models, JSON serialization, and Remote Data Sources talking to Cloud Firestore and Firebase Storage. <strong>Only this layer interacts directly with Firebase.</strong>
    </p>
  </div>
  <div class="card">
    <h4>2. Domain Layer (<code>domain/</code>)</h4>
    <p style="font-size: 9pt; color: #475569; margin: 0;">
      Contains pure Dart business entities, abstract repository interfaces, and focused Use Cases. <strong>Zero Firebase imports — 100% pure Dart business logic.</strong>
    </p>
  </div>
  <div class="card" style="grid-column: span 2;">
    <h4>3. Presentation Layer (<code>presentation/</code>)</h4>
    <p style="font-size: 9pt; color: #475569; margin: 0;">
      Flutter UI screens, reactive widgets, and <strong>Riverpod</strong> state providers. The UI observes providers and calls domain use cases, never querying the database directly.
    </p>
  </div>
</div>

<div class="page-break"></div>

<h3>SOLID Principles in Practice</h3>
<ul>
  <li><strong>Single Responsibility Principle (SRP):</strong> Repositories handle data access; use cases contain a single business rule (e.g., <code>GetProfileUseCase</code>); widgets handle rendering only.</li>
  <li><strong>Open/Closed Principle (OCP):</strong> New behavior is added via new interface implementations. For example, alternative matching algorithms implement the <code>MatchingStrategy</code> interface without modifying existing scoring code.</li>
  <li><strong>Liskov Substitution Principle (LSP):</strong> Abstract repository interfaces can be seamlessly swapped with mock implementations during unit testing without changing client code.</li>
  <li><strong>Interface Segregation Principle (ISP):</strong> Interfaces are small and purpose-specific (e.g. separating <code>AuthRepository</code>, <code>ProfileRepository</code>, and <code>SessionRepository</code>).</li>
  <li><strong>Dependency Inversion Principle (DIP):</strong> High-level domain and presentation layers depend strictly on abstractions, not concrete implementations. Dependency injection is managed cleanly via Riverpod.</li>
</ul>

<!-- SECTION 6 -->
<h2>6. How to Run the Application & Demo Accounts</h2>
<p>
  To launch and test the application on your computer:
</p>

<pre># 1. Download project dependencies
flutter pub get

# 2. Build model serialization code (Freezed / JSON)
dart run build_runner build --delete-conflicting-outputs

# 3. Verify code health
flutter analyze

# 4. Run the app in Google Chrome
flutter run -d chrome</pre>

<h3>Pre-Configured Demo Accounts</h3>
<p>
  Use these pre-seeded demo accounts to explore the app with ready-to-test profiles, localities, and matching data:
</p>
<table>
  <thead>
    <tr>
      <th>Role</th>
      <th>Name</th>
      <th>Locality</th>
      <th>Login Email</th>
      <th>Password</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Elderly</strong></td>
      <td>Somasiri Perera</td>
      <td>Colombo</td>
      <td><code>demo.elderly1@example.com</code></td>
      <td><code>Demo12345!</code></td>
    </tr>
    <tr>
      <td><strong>Volunteer</strong></td>
      <td>Kavindu Silva</td>
      <td>Malabe</td>
      <td><code>demo.volunteer1@example.com</code></td>
      <td><code>Demo12345!</code></td>
    </tr>
    <tr>
      <td><strong>Volunteer</strong></td>
      <td>Nimali Fernando</td>
      <td>Kaduwela</td>
      <td><code>demo.volunteer2@example.com</code></td>
      <td><code>Demo12345!</code></td>
    </tr>
    <tr>
      <td><strong>Volunteer</strong></td>
      <td>Tharindu Perera</td>
      <td>Battaramulla</td>
      <td><code>demo.volunteer3@example.com</code></td>
      <td><code>Demo12345!</code></td>
    </tr>
  </tbody>
</table>

<!-- SECTION 7 -->
<h2>7. Top 5 Frequently Asked Questions (Viva / Presentation Prep)</h2>
<ol>
  <li>
    <strong>Q: What makes CareConnect different from a regular volunteering app?</strong><br>
    <em>A:</em> Traditional apps focus on large group events or organizational projects. CareConnect is built for <strong>1-on-1 micro-volunteering</strong> with an <strong>accessibility-first interface</strong> tailored for elderly users and an automated <strong>Trust Score system</strong> to guarantee personal safety.
  </li>
  <li>
    <strong>Q: How does the platform protect elderly users from scams or harm?</strong><br>
    <em>A:</em> Volunteers must upload an official identity document (NIC/Passport) that is verified by an administrator before they receive a verified badge. Completed visits are rated, and emergency contact details can be called with a single tap.
  </li>
  <li>
    <strong>Q: How does the matching algorithm work?</strong><br>
    <em>A:</em> The matching algorithm evaluates locality proximity, matching skills (e.g. tech assistance or grocery shopping), matching availability windows, and prior trust score ratings to produce a ranked compatibility score.
  </li>
  <li>
    <strong>Q: Why did you choose Clean Architecture instead of simple MVC?</strong><br>
    <em>A:</em> Clean Architecture decouples the core business logic from third-party tools like Firebase and Flutter UI. This ensures domain rules are 100% testable in pure Dart, code doesn't break when UI changes, and multiple developers can work in parallel.
  </li>
  <li>
    <strong>Q: How does the Senior Accessibility framework work?</strong><br>
    <em>A:</em> It provides dynamic text scaling (up to 1.6x), high contrast borders and backgrounds, and simplified layouts with large touch targets, managed globally through an <code>AccessibilityController</code>.
  </li>
</ol>

</body>
</html>
"""

with open("CareConnect_Project_Complete_Guide.html", "w", encoding="utf-8") as f:
    f.write(html_content)

print("Generated HTML successfully.")

edge_path = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
chrome_path = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
browser_path = edge_path if os.path.exists(edge_path) else chrome_path

input_html = os.path.abspath("CareConnect_Project_Complete_Guide.html")
output_pdf = os.path.abspath("CareConnect_Project_Complete_Guide.pdf")

cmd = [
    browser_path,
    "--headless",
    "--disable-gpu",
    "--no-pdf-header-footer",
    f"--print-to-pdf={output_pdf}",
    f"file:///{input_html}"
]

res = subprocess.run(cmd, capture_output=True, text=True)
if res.returncode == 0 and os.path.exists(output_pdf):
    print(f"PDF successfully updated: {output_pdf} (Size: {os.path.getsize(output_pdf)} bytes)")
else:
    print(f"Error during PDF conversion: {res.stderr}")
