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
