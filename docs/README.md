# Winnie GitHub Pages Site

This folder is a static marketing site for GitHub Pages.

## Local Preview

Open `docs/index.html` in a browser, or serve the folder:

```powershell
python -m http.server 8000 -d docs
```

## GitHub Pages

In the repository settings, set Pages to deploy from:

- Branch: `main`
- Folder: `/docs`

The page uses only static HTML, CSS, PNG screenshots, and the local Winnie logo asset.

## Refresh Screenshots

With the local Docker stack running and demo data enabled:

```powershell
powershell -ExecutionPolicy Bypass -File .\docs\capture-screenshots.ps1
```

The script logs into `demo@example.com`, captures the current dashboard in headless Edge,
and refreshes the PNG screenshots in `docs/assets`.
