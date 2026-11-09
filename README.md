# sbx-dev-sandbox

Prebuilt [Docker Sandbox](https://docs.docker.com/ai/sandboxes/) templates with common
toolchains, so every project works without per-project setup.

**Included:** JDK 17 / 21 / 25 (Temurin), Maven, Rust, Python 3, build essentials, glab.
See [`context/sandbox-environment.md`](context/sandbox-environment.md). It is copied into
the image so the agent knows what's available.

## Usage

```console
sbx run claude --template ghcr.io/<owner>/sbx-dev-sandbox:claude-code
```

Pin a dated tag (e.g. `claude-code-20261109`) for reproducibility.

## Images

| Tag                       | Base                                  |
|---------------------------|---------------------------------------|
| `claude-code`             | `docker/sandbox-templates:claude-code` |
| `claude-code-YYYYMMDD`    | same, frozen weekly build             |

Built for `linux/amd64` and `linux/arm64` on every push to `main` and weekly.

## Building locally

Build the image, export it, load it into `sbx`, and run it:

```console
docker build -t my-template:v1 .
docker image save my-template:v1 -o my-template.tar
sbx template load my-template.tar
sbx run -t my-template:v1 claude
```

## Adding an agent

Add it to the `matrix.agent` list in `.github/workflows/build.yml`. The value must match a
tag of `docker/sandbox-templates`.

## Credentials

The image contains no secrets. Store tokens on the host with `sbx secret`; the
sandbox proxy injects them into outgoing requests.

### GitLab token (glab)

Set the token globally on the host. The sandbox only sees a placeholder; the proxy
substitutes the real value for requests to `gitlab.com`:

```console
sbx secret set-custom -g \
  --host gitlab.com \
  --env GITLAB_TOKEN \
  --value <your-token>
```

Never run `glab auth login` inside the sandbox.

## Updating tool versions

Bump `MAVEN_VERSION` / `GLAB_VERSION` in the `Dockerfile`. When you add or remove a tool,
update `context/sandbox-environment.md` in the same commit.
