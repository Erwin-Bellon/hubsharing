# HubSharing FHIR Implementation Guide

A FHIR Implementation Guide (IG) that defines how telemonitoring diagnostic data (e.g., Holter monitoring reports) can
be shared using the Hubs in the Belgian healthcare ecosystem. It profiles `DiagnosticReport` as the
canonical carrier resource and maps proprietary telemonitoring messages to FHIR R4-compliant structures.

**Depends on**: `hl7.fhir.be.patient-monitoring` (HL7 Belgium Patient Monitoring IG)

---

## Prerequisites

The recommended way to work on this project is via the included **devcontainer**. It provides:

- Node.js 22 + SUSHI (FSH compiler)
- Java 21 (IG Publisher runtime)
- Ruby + Jekyll (HTML generation)

> Without the devcontainer, install these manually: JDK 17+, Node.js 20+, Ruby, Jekyll, and SUSHI (
`npm install -g fsh-sushi`).

---

## Opening the devcontainer

> **⚠️ Do not run both Rancher Desktop and Podman Desktop at the same time.**
> Having both installed can cause conflicts over the `docker_engine` named pipe, leaving your container runtime stuck
> in an initializing loop. **Rancher Desktop is the recommended and tested option** — if Podman Desktop is also
> installed, uninstall it (or at minimum ensure it is fully stopped and its background services are not running)
> before starting Rancher Desktop.

### VS Code

1. Install
   the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
2. In Rancher Desktop preferences, select **dockerd (Moby)** as the container engine — the Docker-compatible socket is
   then picked up automatically by VS Code
3. Open the repo folder in VS Code
4. Press **Ctrl+Shift+P** → **Dev Containers: Reopen in Container**
5. Wait for the container to build (first time only), then use the integrated terminal

### IntelliJ IDEA

Requires IntelliJ IDEA 2023.1 or later.

1. In Rancher Desktop preferences, select **dockerd (Moby)** as the container engine — this exposes a
   Docker-compatible socket automatically
2. Configure IntelliJ to use that socket:
    - Go to **Settings → Build, Execution, Deployment → Docker**
    - Add a new connection and choose **Docker for Windows** (or **Unix socket** on macOS/Linux) — IntelliJ picks up
      the Rancher Desktop socket without extra configuration
    - Click **Test connection** to verify
3. Open the repo folder in IntelliJ
4. When prompted, click **"Reopen in Dev Container"** — or go to **File → Remote Development → Dev Containers → Open
   Folder in Dev Container**
5. Use the built-in terminal once inside the container

---

## Build

### Inside the devcontainer (recommended)

The devcontainer runs Linux, so always use the `.sh` scripts - `.bat` files will not work.

First, navigate to the project folder. The devcontainer config pins the mount point so it is the same for all IDEs:

```bash
cd /workspaces/hubsharing
```

If `_build.sh` was created or edited on Windows, it may have CRLF line endings that prevent it from running. Fix this once before the first build:

```bash
sed -i 's/\r//' _build.sh
```

Then run:

```bash
bash _build.sh
```

**Outside the devcontainer on Windows:**

```bat
_build.bat
```

Both scripts present an interactive menu:

| Option | Action                                       |
|--------|----------------------------------------------|
| 1      | Download / update `publisher.jar`            |
| 2      | Full build (SUSHI → IG Publisher)            |
| 3      | Build without re-running SUSHI               |
| 4      | Build without terminology server (`-tx n/a`) |
| 5      | Jekyll-only build                            |
| 6      | Clean temp directories                       |

On first use, choose **1** to download the IG Publisher JAR (~200 MB), then **2** to build.

The build output lands in `output/`.

---

## Preview locally

### Inside the devcontainer (Linux)

```bash
bash _serve.sh
```

### Outside the devcontainer on Windows

`_serve.sh` is a bash script and will not run directly on Windows. Run the equivalent command in PowerShell instead:

```powershell
npx http-server output/en -p 8080 -c-1 -o
```

Both options serve the generated site at `http://localhost:8080` and open a browser tab.

---

## CI / Deployment

Pushing to `main` triggers `.github/workflows/publish.yml`, which:

1. Installs SUSHI and Jekyll
2. Downloads the IG Publisher (cached between runs)
3. Runs a full build
4. Deploys `output/` to **GitHub Pages**

---

## Repository layout

```
input/
  fsh/              # FHIR Shorthand source (profiles, extensions, examples)
  pagecontent/      # Narrative documentation (Markdown → rendered HTML pages)
fsh-generated/      # Auto-generated FHIR JSON/XML (do not edit manually)
output/             # Final built website (git-ignored)
sushi-config.yaml   # Package metadata and menu structure
ig.ini              # IG Publisher entry-point config
_build.sh / .bat    # Build helpers
_serve.sh           # Local preview server
.devcontainer/      # Dev container definition
.github/workflows/  # CI pipeline
```

---

## Key definitions

| Artifact                         | Description                                                                         |
|----------------------------------|-------------------------------------------------------------------------------------|
| `TelemonitoringDiagnosticReport` | Core profile - extends `DiagnosticReport` for hub-compatible telemonitoring results |
| `TelemonitoringId`               | Extension - session identifier (required)                                           |
| `Carepath`                       | Extension - carepath id + optional version                                          |
| `PrescriberApplication`          | Extension - originating application name                                            |
| `SourceTelemonitoringReport`     | Extension - back-reference to the source report                                     |
