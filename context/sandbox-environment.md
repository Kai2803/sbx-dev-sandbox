# Sandbox environment

You are running inside a Docker sandbox built from a shared template.
The following tools are preinstalled. Prefer them over installing anything new.

## Java
- JDKs: /opt/jdk-17, /opt/jdk-21, /opt/jdk-25 (default, on PATH)
- Switch per command: `JAVA_HOME=/opt/jdk-17 ./gradlew build`
- Gradle detects all three automatically (they live in /usr/lib/jvm).
- Maven: `mvn` on PATH. Prefer a project's `./mvnw` / `./gradlew` wrapper if present.
- Do not download or install other JDKs. If a project needs a version
  that isn't listed, stop and ask.

## Other toolchains
- Rust: rustup, cargo, clippy, rustfmt
- Python 3 with pip and venv. Create a venv per project; don't install globally.
- Build essentials: gcc, make, pkg-config, OpenSSL headers

## GitLab
- `glab` is installed. Authentication is handled by a proxy outside the sandbox.
- The token variables you see contain placeholders. This is expected.
- Never run `glab auth login` or try to change GitLab credentials.
