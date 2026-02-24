# Vercel Deployment Guide: web-next

This guide explains how to deploy the Next.js version of BRAAND (`web-next`) to Vercel.

## 🚀 Easy Deployment (Recommended)

### 1. Push to GitHub
If you haven't already, push your current project to a GitHub repository.

### 2. Connect to Vercel
1. Go to [vercel.com](https://vercel.com) and sign in.
2. Click **"Add New"** -> **"Project"**.
3. Import your GitHub repository.

### 3. Critical Configuration (Subfolder setup)
Since the Next.js app is in a subfolder, you **must** configure these settings during import:

*   **Framework Preset**: Next.js
*   **Root Directory**: Click "Edit" and select `web-next`.
*   **Environment Variables**: Add your Supabase keys from `.env.local`:
    *   `NEXT_PUBLIC_SUPABASE_URL`
    *   `NEXT_PUBLIC_SUPABASE_ANON_KEY`

### 4. Deploy
Click **"Deploy"**. Vercel will build and host your site automatically!

---

## 🛠️ CLI Deployment (Alternative)

1. **Install Vercel CLI**:
   ```bash
   npm install -g vercel
   ```

2. **Deploy from project root**:
   ```bash
   vercel
   ```
   *When prompted for the project path, ensure you point to the `web-next` directory.*

## 🔒 Security Note
After deployment, add your new Vercel URL (e.g., `https://braand-next.vercel.app`) to your **Supabase Dashboard** under **Settings -> API -> Allowed Origins** to enable CORS for Authentication.
