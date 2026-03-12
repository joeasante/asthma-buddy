# Hetzner Deployment Guide — Asthma Buddy

## Architecture Overview

```
Internet
   │
   ▼
CloudPanel Nginx (ports 80 + 443) ← owns SSL, manages TLS certs
   │  reverse proxy for yourdomain.com
   ▼
localhost:3000 (host port)
   │
   ▼
Docker container: asthma_buddy (Thruster on port 80 inside container)
   │
   └── SQLite databases → /rails/storage → Docker volume on host
```

**Why no kamal-proxy:** kamal-proxy (Kamal 2.x's built-in proxy) binds to ports 80 and 443.
CloudPanel's Nginx already owns those ports. Running both would cause a port conflict and
take down all existing CloudPanel sites. The solution is to skip kamal-proxy entirely and
let CloudPanel's Nginx act as the reverse proxy instead.

---

## Part 1 — Pre-Deployment Checklist

### On your Mac Mini (local)
- [ ] Docker Desktop installed and running
- [ ] Kamal installed (`gem install kamal` or already in Gemfile)
- [ ] SSH key set up for your Hetzner server
- [ ] GitHub account for container registry (ghcr.io)

### On the Hetzner VPS
- [ ] CloudPanel running with existing sites live
- [ ] Root or sudo SSH access
- [ ] Docker NOT yet installed (Kamal will install it)
- [ ] Your domain DNS pointing to the server's IP

---

## Part 2 — Port Conflict Analysis

| Service          | Host Ports     | Notes                              |
|------------------|----------------|------------------------------------|
| CloudPanel Nginx | 80, 443        | Must keep — owns all existing sites|
| CloudPanel UI    | 8443           | CloudPanel admin interface         |
| kamal-proxy      | 80, 443        | **SKIP THIS** — conflicts with Nginx|
| Asthma Buddy     | 127.0.0.1:3000 | Internal only, proxied by Nginx    |
| Docker daemon    | none           | Unix socket only                   |

**Resolution:** Do not deploy kamal-proxy. Expose the app container only on `127.0.0.1:3000`
(loopback only — not accessible from the internet directly). CloudPanel Nginx proxies to it.

---

## Part 3 — Container Registry Setup

The current `registry.server: localhost:5555` only works for local builds. For a remote
deployment you need a real registry. GitHub Container Registry (ghcr.io) is free and you
already use GitHub.

### Create a GitHub Personal Access Token

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token with scopes: `write:packages`, `read:packages`, `delete:packages`
3. Copy the token — you'll use it as `KAMAL_REGISTRY_PASSWORD`

---

## Part 4 — Kamal Configuration

### 4a. Update `config/deploy.yml`

Replace the entire file with:

```yaml
service: asthma_buddy
image: ghcr.io/YOUR_GITHUB_USERNAME/asthma-buddy

servers:
  web:
    hosts:
      - YOUR_HETZNER_IP
    options:
      publish:
        - "127.0.0.1:3000:80"   # map container port 80 to loopback:3000 only

# No proxy section — we skip kamal-proxy entirely.
# CloudPanel's Nginx will act as the reverse proxy.

registry:
  server: ghcr.io
  username: YOUR_GITHUB_USERNAME
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  secret:
    - RAILS_MASTER_KEY
  clear:
    SOLID_QUEUE_IN_PUMA: true
    APP_HOST: "asthmabuddy.yourdomain.com"   # your actual domain

# SSH user (CloudPanel servers often use a non-root deploy user)
# If you SSH as root, leave this commented out.
# ssh:
#   user: deploy

# Build for amd64 (Hetzner is x86_64, your Mac might be Apple Silicon)
builder:
  arch: amd64
  # Optional: build remotely on the Hetzner server itself (faster than cross-compiling)
  # remote: ssh://root@YOUR_HETZNER_IP

# Persistent storage for SQLite databases and Active Storage files
volumes:
  - "asthma_buddy_storage:/rails/storage"

asset_path: /rails/public/assets

aliases:
  console: app exec --interactive --reuse "bin/rails console"
  shell:   app exec --interactive --reuse "bash"
  logs:    app logs -f
  dbc:     app exec --interactive --reuse "bin/rails dbconsole --include-password"
```

Replace placeholders:
- `YOUR_GITHUB_USERNAME` — your GitHub username (lowercase)
- `YOUR_HETZNER_IP` — your server's public IP
- `asthmabuddy.yourdomain.com` — your actual domain

### 4b. Update `.kamal/secrets`

```bash
# Pull registry password from shell environment
KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD

# Pull Rails master key from shell environment
RAILS_MASTER_KEY=$RAILS_MASTER_KEY
```

These reference environment variables — never put raw values here. See Part 5 for how to
set these securely on your Mac.

---

## Part 5 — Secrets Management

### Local secrets (Mac Mini)

Create `~/.asthma-buddy-secrets` (outside the repo, never committed):

```bash
export KAMAL_REGISTRY_PASSWORD="ghp_your_github_pat_here"
export RAILS_MASTER_KEY="$(cat /path/to/asthma-buddy/config/master.key)"
```

Add to your `~/.zshrc` or source before deploying:

```bash
source ~/.asthma-buddy-secrets
```

### Rails master key on the server

Kamal injects `RAILS_MASTER_KEY` as an environment variable into the container.
The `config/master.key` file should NOT be on the server at all — the container gets
the key via the injected env var.

Verify `.gitignore` includes:
```
config/master.key
```

### Credentials file

`config/credentials.yml.enc` IS committed to git and is safe — it's encrypted.
The master key decrypts it at runtime inside the container.

---

## Part 6 — CloudPanel Nginx Configuration

### Create the vhost in CloudPanel

1. Log into CloudPanel (https://your-server:8443)
2. Go to **Sites** → **Add Site** → Choose **Reverse Proxy**
   - Domain: `asthmabuddy.yourdomain.com`
   - Upstream URL: `http://127.0.0.1:3000`
3. After creating, go to the site's **SSL/TLS** tab and issue a Let's Encrypt certificate

### Manual Nginx config (if CloudPanel's UI doesn't expose all options)

CloudPanel stores vhost configs in `/etc/nginx/sites-enabled/`. Find your site's config
and ensure these proxy headers are set — they're required for Rails to work correctly
behind a proxy:

```nginx
location / {
    proxy_pass         http://127.0.0.1:3000;
    proxy_http_version 1.1;

    proxy_set_header   Host              $host;
    proxy_set_header   X-Real-IP         $remote_addr;
    proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwarded-Proto $scheme;   # tells Rails the request is HTTPS

    proxy_read_timeout 60s;
    proxy_send_timeout 60s;
    proxy_buffering    off;

    # Required for Turbo Streams (Server-Sent Events)
    proxy_cache        off;
    proxy_set_header   Connection "";
}
```

The `X-Forwarded-Proto: https` header is what makes `config.assume_ssl = true` work.
Rails reads this header and treats the connection as secure.

### Reload Nginx after any config changes

```bash
nginx -t && systemctl reload nginx
```

---

## Part 7 — First Deployment (Step by Step)

```bash
# 1. Source your secrets
source ~/.asthma-buddy-secrets

# 2. Verify Kamal can connect to your server
bin/kamal server exec "echo connected"

# 3. Bootstrap the server (installs Docker, does NOT install kamal-proxy)
#    This only needs to run once.
bin/kamal server bootstrap

# 4. Build and push the image to ghcr.io
bin/kamal build push

# 5. Deploy the app (starts the container with the published port mapping)
bin/kamal deploy

# 6. Verify the container is running and the port is listening
bin/kamal server exec "docker ps"
bin/kamal server exec "ss -tlnp | grep 3000"

# 7. Run database migrations (first deploy only)
bin/kamal app exec "bin/rails db:migrate"
```

After step 5, the container is accessible at `127.0.0.1:3000` on the server.
After setting up the CloudPanel vhost (Part 6), it will be accessible at your domain.

---

## Part 8 — Subsequent Deployments

Normal workflow after the initial setup:

```bash
source ~/.asthma-buddy-secrets
bin/kamal deploy
```

Kamal will:
1. Build a new image on your Mac (cross-compiled for amd64)
2. Push it to ghcr.io
3. Pull the new image on the Hetzner server
4. Start the new container
5. Run the entrypoint (which runs `db:prepare` — handles migrations automatically)
6. Stop the old container

There is a brief downtime (~5–10 seconds) during the container swap because there's no
kamal-proxy to hold traffic. For a personal health app this is acceptable. If zero-downtime
is ever needed, kamal-proxy can be introduced on ports 8080/8443 with Nginx fronting it.

---

## Part 9 — Testing the Deployment Without Affecting Live Sites

### Step 1: Test on a staging subdomain first

Before pointing your real domain at the app:
1. Create a CloudPanel vhost for `staging.yourdomain.com` pointing to `127.0.0.1:3000`
2. Add `staging.yourdomain.com` to `APP_HOST` (or use a separate staging deploy config)
3. Deploy and verify everything works at the staging URL

### Step 2: Health check endpoint

Rails exposes `/up` for health checks (built into Rails 8). Test it:

```bash
# From the server itself
curl http://127.0.0.1:3000/up

# From your Mac (after CloudPanel vhost is set up)
curl https://staging.yourdomain.com/up
```

Expected response: `200 OK` with body `{ "status": "ok" }`.

### Step 3: Verify no impact on existing sites

CloudPanel sites are untouched because:
- The app container only binds to `127.0.0.1:3000` (loopback — not accessible externally)
- No changes are made to other Nginx vhosts
- Docker runs alongside Nginx without interfering

Test an existing site still loads after deployment:
```bash
curl -I https://existing-site.yourdomain.com
```

### Step 4: Check logs

```bash
# App logs
bin/kamal logs

# Nginx access logs (on the server)
tail -f /var/log/nginx/asthmabuddy.yourdomain.com.access.log
```

---

## Part 10 — Firewall Considerations

Ensure these ports are open on your Hetzner firewall (Hetzner Cloud console or `ufw`):

| Port | Protocol | Purpose             |
|------|----------|---------------------|
| 22   | TCP      | SSH                 |
| 80   | TCP      | HTTP (redirect only)|
| 443  | TCP      | HTTPS               |
| 8443 | TCP      | CloudPanel admin    |

Port 3000 does NOT need to be open — it's `127.0.0.1` (loopback) only.

```bash
# If using ufw
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8443/tcp
ufw enable
```

---

## Part 11 — Troubleshooting

| Problem | Check |
|---------|-------|
| 502 Bad Gateway | Container not running: `bin/kamal server exec "docker ps"` |
| SSL errors | Let's Encrypt cert not issued yet; check CloudPanel SSL tab |
| App returns HTTP not HTTPS | `X-Forwarded-Proto` header missing from Nginx config |
| `APP_HOST` errors | Env var not set in deploy.yml or secrets not sourced |
| Image push fails | Token not in env: `echo $KAMAL_REGISTRY_PASSWORD` |
| Cross-compile too slow | Add `remote: ssh://root@YOUR_HETZNER_IP` to builder section |
| DB missing on fresh server | Run `bin/kamal app exec "bin/rails db:prepare"` |
