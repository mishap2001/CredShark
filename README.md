# Phishing Simulation Framework (Educational Lab)

## ⚠️ Disclaimer

This project was created **strictly for educational purposes in an isolated lab environment**.

Its purpose is to analyze phishing infrastructure automation from a **defensive cybersecurity perspective** — not to deploy or conduct real-world attacks.

---

## 🎯 Purpose

This project demonstrates how phishing infrastructure can be automated using Bash scripting, with the goal of understanding:

 - Environment setup (Apache, PHP, TLS tooling)
 - HTTPS configuration via automated certificate issuance
 - Web hosting logic (domain-based or local)
 - Page deployment (template-based or cloned structure)
 - PHP-based server-side capturing through form submission handling
 - URL shortening behavior to analyze obfuscation tactics


---

## 🧠 High-Level Workflow

### 1️⃣ Environment Configuration

The script automatically verifies required components:

- `wget` – for page cloning (lab simulation)
- `apache2` – local HTTP web server
- `certbot` – TLS/SSL certificate automation
- `php` – server-side form processing logic

Missing tools are installed automatically.

---

### 2️⃣ Hosting Configuration

- If a custom domain is provided:
  - TLS certificate configuration is attempted via Certbot
  - HTTPS is enabled (when validation succeeds)

- If no domain is provided:
  - The site is hosted locally via Apache
  - Exposed over HTTP on the host machine’s IP

---

### 3️⃣ Website Deployment

The user can simulate:

- Cloning a publicly accessible login page structure
- Using built-in template-based login pages (for lab use only)

---

### 4️⃣ Server-Side Logic

A custom PHP handler is generated to simulate credentials capturing by processing and storing submitted form data for defensive analysis.

Captured data is stored in a structured JSON format.

---

### 5️⃣ URL Obfuscation Simulation

The framework demonstrates how URL shortening services can be leveraged to obscure final destinations.

---
