# flutter_application_inventorymanagement

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Deploy web to DigitalOcean (small droplet)

The `web` Docker image **does not compile Flutter on the server**. You build on your PC, commit `build/web/`, then deploy (GitHub Actions or `docker compose up -d --build`).

### 1. Confirm you are on the right server (SSH)

```powershell
ssh root@YOUR_DROPLET_IP
hostname   # expect ubuntu-s-1vcpu-512mb-10gb-sgp1-01 (or your droplet name)
pwd        # e.g. /root/inventoryQR after cd
```

If `hostname` / IP match the DigitalOcean dashboard, you are on the deployed machine.

### 2. Build web on Windows (repo root)

```powershell
.\scripts\build_web_prod.ps1
```

Or manually:

```powershell
flutter pub get
flutter build web --release --dart-define=API_BASE_URL=https://api.medtechinventorysystem.org
```

### 3. Ship the bundle

```powershell
git add build/web
git commit -m "Update production web bundle"
git push origin main
```

Your existing workflow (SSH + `git pull` + `docker compose up -d --build`) will rebuild the **nginx-only** `web` image quickly.

### 4. After changing API URL or Flutter UI

Always re-run step 2, then commit `build/web/` again before deploy.

### Cloudflare **Error 521** (“Web server is down”)

Cloudflare reaches the internet, but **nothing answers** on your droplet (or on the port/SSL mode Cloudflare uses).

1. **SSL/TLS mode (very common)**  
   Nginx in this repo listens on **HTTP port 80 only** (no HTTPS on the droplet). In Cloudflare: **SSL/TLS → Overview**, set encryption to **Flexible** so Cloudflare talks to your origin on **port 80**.  
   If you use **Full** or **Full (strict)**, Cloudflare expects **HTTPS on port 443** on the droplet; with no TLS there, you often get **521**.

2. **Docker not running**  
   On the server:
   ```bash
   cd ~/inventoryQR && git pull origin main
   docker compose ps
   docker compose up -d --build --remove-orphans
   ```
   Then test on the droplet:
   ```bash
   curl -sI -H "Host: admin.medtechinventorysystem.org" http://127.0.0.1/
   ```
   You should see HTTP `200` or `301/302` from nginx, not “connection refused”.

3. **`build/web` missing on the server**  
   If `ls ~/inventoryQR/build/web` fails, run `git pull origin main` (your deploy must include the committed `build/web` folder). Without it, the `web` image build fails.

### Windows vs Linux commands

- **`cd ~/inventoryQR`** is for **Linux (SSH on the droplet)**. On Windows PowerShell, use your real project path, e.g.  
  `cd "C:\3rd Year\SEM 2\SIA 2\QR CODE INVENTORY MANAGEMENT SYSTEM\inventoryQR"`.
- **`docker compose up`** on your **PC** needs **Docker Desktop running**. Production deploy is normally **GitHub Actions** or **SSH into the droplet** and run `docker compose` **there**.

### MariaDB `Access denied for user 'root'` / API `db_error`

Compose now sets **`MYSQL_ROOT_PASSWORD`** (default `medlab_root_change_me`, or set **`MYSQL_ROOT_PASSWORD`** in a `.env` file on the server — see `.env.example`).

**Important:** If the database volume already exists, MariaDB will **not** re-run init scripts or change the root password. After pulling this update, **one-time** reset the volume (this **deletes DB data**; backup first if needed):

```bash
cd ~/inventoryQR
docker compose down
docker volume rm inventoryqr_db_data
# If the name differs: docker volume ls | grep db_data
docker compose up -d --build
```

Then `docker compose exec api php -r "new PDO('mysql:host=db;dbname=medlab_inventory','root','YOUR_PASSWORD');"` should succeed (use the same password as in `.env` or the default above).
