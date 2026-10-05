# CyberCTF Lab Philosophy

Cyber CTF lab philosophy.

This document captures the guiding principles, constraints, and actionable rules that Cursor rules and authors must follow when generating labs for the CyberCTF ecosystem. The goal is to ensure every generated lab is realistic, pedagogically useful, safe, reproducible, and produces a realistic artefact as proof of exploitation, the kind of evidence a pentester would include in a professional report.

> Short summary: labs must model realistic systems and business context. CyberCTF is about doing the pentest, not collecting flags: the proof is the evidence, a real business artefact (credentials, customer data, invoice totals, API tokens, service responses) that is only retrievable via the documented vulnerability. No “magic strings”, no `CTF{...}`, no points.


## Core principles

1.	Realism first. Every lab must be grounded in a plausible business or operational scenario (service type, deployment topology, assets at risk). The scenario should look like something you’d encounter during a real penetration test.

2.	Exploit-as-proof. The evidence is an artefact that has legitimate existence in the system (environment variable, API key stored in vault, customer PII in a file, database secret, or a privileged API response). It must not be a contrived string whose only purpose is to be a flag.

3.	Per-player evidence, deterministic tests. Lab repositories are public, so they never contain a player's evidence: a lab declares the evidence's kind and a public development value, receives each player's own value at startup, and places it in its data (see context/EVIDENCE.md and apps/run/EVIDENCE-INJECTION.md). CI and pytest always run with the fixed development value, so validation stays reproducible. The artefact’s location and type must make sense in the scenario and be reachable only by exploiting the vulnerability.

4.	No spoilers in player-facing artifacts. README, UI text, logs visible to players, and Docker image labels must not contain vulnerability descriptions, hints, or the evidence value. Maintain a strict separation between maintainer comments and player-facing content.

5.	Pedagogy and difficulty calibration. Each lab must include clear prerequisites and an estimated time. The exploit path should map to the declared difficulty and teachable skill(s).

6.	Testability and CI-first design. All labs must include automated tests (tests/) and a self-check (`checks:` in isoloom.yml).

8.	One description, every target. A lab is its `isoloom.yml`: every machine has a container edition and a VM edition, so the same lab runs on the player's machine, a server, a cloud or hosted. Containers are the light option; VMs set the bar.

7.	Safety and legal compliance. No lab may include code or configuration that meaningfully facilitates wrongdoing outside an isolated, ephemeral lab environment. Avoid including real credentials, privileged cloud APIs, or any content that could be abused in the wild.
