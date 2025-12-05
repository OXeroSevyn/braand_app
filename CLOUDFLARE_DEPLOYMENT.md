# Cloudflare Pages Deployment Guide

Cloudflare Pages is an excellent alternative to Netlify, offering **unlimited bandwidth** and **unlimited requests** on their free tier.

## Option 1: Drag & Drop (Easiest)

1.  **Build your web app** (already done):
    ```bash
    flutter build web --release
    ```
2.  **Go to Cloudflare Dashboard**:
    - Visit [dash.cloudflare.com](https://dash.cloudflare.com)
    - Sign up or log in.
3.  **Create a Project**:
    - Navigate to **"Workers & Pages"** on the sidebar.
    - Click **"Create Application"** -> **"Pages"** tab.
    - Select **"Upload Assets"**.
4.  **Deploy**:
    - Name your project (e.g., `braandins-app`).
    - Drag and drop the `build/web` folder from your project into the upload area.
5.  **Done!**
    - Cloudflare will give you a URL like `https://braandins-app.pages.dev`.

## Option 2: Git Integration (Recommended)

1.  **Push your code** to a GitHub/GitLab repository.
2.  **Connect to Cloudflare**:
    - In Cloudflare Dashboard -> Workers & Pages -> Create Application -> Pages -> **"Connect to Git"**.
3.  **Configure Build**:
    - **Framework preset**: `Flutter` (if available) or `None`.
    - **Build command**: `flutter build web --release`
    - **Build output directory**: `build/web`
4.  **Save and Deploy**.

## Important: Single Page App (SPA) Routing

Cloudflare Pages needs a `_routes.json` or a specific setup for SPA routing (handling page refreshes), similar to Netlify's `_redirects`.

However, for simple SPAs, Cloudflare often handles `index.html` fallbacks automatically if you use the Git integration. If you use Drag & Drop, it usually just works, but if you face 404s on refresh:

1.  Create a file named `_routes.json` in your `web` folder (and rebuild) or directly in `build/web`.
2.  Content:
    ```json
    {
      "version": 1,
      "include": ["/*"],
      "exclude": ["/assets/*"]
    }
    ```
    *Note: Cloudflare Pages usually handles SPA routing by default now, but this is a fallback.*

## Comparison with Netlify

| Feature | Netlify Free | Cloudflare Pages Free |
| :--- | :--- | :--- |
| **Bandwidth** | 100GB / month | **Unlimited** |
| **Build Minutes** | 300 mins / month | 500 mins / month |
| **Requests** | Limited | **Unlimited** |
| **Sites** | Unlimited | Unlimited |

## Supabase Configuration

Don't forget to update your Supabase settings!

1.  Go to Supabase Dashboard -> Settings -> API.
2.  Add your new Cloudflare URL (e.g., `https://your-app.pages.dev`) to **Allowed Origins**.
