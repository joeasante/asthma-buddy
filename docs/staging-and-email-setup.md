# Staging Server & Email Setup

## Status

| Task | Status |
|---|---|
| `config/deploy.staging.yml` created | ✅ Done |
| Resend API key added to credentials | ✅ Done |
| Production email config (SMTP) | ✅ Done |
| Dev email config (letter_opener) | ✅ Done |
| Staging VPS provisioned | ⏳ TODO |
| Resend domain verified | ⏳ TODO |

---

## Part 1 — Email (Resend)

### How email works per environment

| Environment | Method | What happens |
|---|---|---|
| Dev | `letter_opener` | Email opens as a browser tab instantly — no setup needed |
| Production | Resend SMTP | Real email delivered to the user's inbox |
| Staging | Resend SMTP | Same as production — real emails sent from `staging.asthmabuddy.app` |

### TODO: Verify your domain in Resend

The Resend API key (`re_ERFLF8xv_...`) is already saved in `config/credentials.yml.enc`. You just need to verify the domain so Resend will actually send from it.

1. Log in at **resend.com**
2. Go to **Domains** → **Add Domain** → enter `asthmabuddy.app`
3. Resend will give you 3 DNS records to add. In **Cloudflare** (for `asthmabuddy.app`), add:
   - A **TXT** record for SPF
   - A **TXT** record for DKIM (there may be two DKIM records)
   - A **TXT** record for DMARC
4. Click **Verify** in Resend — it turns green within a few minutes
5. That's it. Production emails will now deliver.

> **Note:** The `from:` address is already configured as `Asthma Buddy <noreply@asthmabuddy.app>` in `app/mailers/application_mailer.rb`.

---

## Part 2 — Staging Server

### Why staging exists

Staging is a production-identical environment you deploy to *before* production. It catches broken deploys, migration issues, and config problems before real users are affected.

**Workflow:**
```
Dev → bin/kamal deploy -d staging → verify → bin/kamal deploy → production
```

### TODO: Provision the staging server

#### Step 1 — Create a Hetzner VPS

1. Go to **console.hetzner.cloud**
2. Create a new server:
   - **Location:** Same region as production (e.g. Nuremberg)
   - **Image:** Ubuntu 24.04
   - **Type:** CX11 (2 vCPU, 2 GB RAM — €4/month is enough)
   - **SSH key:** Add your existing SSH key
3. Note the **public IP address** — you'll need it below

#### Step 2 — Install CloudPanel

SSH into the new server and follow the same CloudPanel setup you did for production (see `docs/hetzner-deployment.md`).

#### Step 3 — Update deploy.staging.yml

Open `config/deploy.staging.yml` and replace the placeholder:

```yaml
servers:
  web:
    hosts:
      - STAGING_SERVER_IP   # ← replace this with your actual staging VPS IP
```

#### Step 4 — Add DNS in Cloudflare

Add an **A record** in Cloudflare:
- **Name:** `staging`
- **Value:** staging VPS IP
- **Proxy:** Proxied (orange cloud) ✅

This makes `staging.asthmabuddy.app` point to your staging server.

#### Step 5 — Create the site in CloudPanel (on the staging server)

SSH into the staging server and set up a CloudPanel site for `staging.asthmabuddy.app` with the same Nginx vhost config as production — reverse proxy to `127.0.0.1:3000`.

Refer to the production setup in `docs/hetzner-deployment.md` for the exact Nginx config.

#### Step 6 — First deploy to staging

Run these from your local machine (with `KAMAL_REGISTRY_PASSWORD` and `RAILS_MASTER_KEY` set):

```bash
# Install kamal-proxy on the staging server
bin/kamal proxy boot -d staging

# Deploy the app to staging
bin/kamal deploy -d staging
```

The first deploy will:
- Pull the Docker image from ghcr.io
- Run `db:prepare` (creates a fresh SQLite database)
- Start the app at `staging.asthmabuddy.app`

#### Step 7 — Verify it works

Visit `https://staging.asthmabuddy.app` and register a test account. Staging has its own completely separate database (`asthma_buddy_staging_storage` volume) — it never shares data with production.

---

## Day-to-day workflow once staging is set up

```bash
# 1. Deploy to staging first
bin/kamal deploy -d staging

# 2. Test at https://staging.asthmabuddy.app

# 3. If good, deploy to production
bin/kamal deploy
```

### Useful staging commands

```bash
bin/kamal logs -d staging              # tail staging logs
bin/kamal console -d staging           # Rails console on staging
bin/kamal app exec -d staging -- bash  # shell on staging container
bin/kamal proxy reboot -d staging      # restart kamal-proxy on staging
```
