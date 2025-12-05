# Netlify Deployment Guide

This guide will help you deploy your BRAANDINS Flutter web app to Netlify.

## Prerequisites

- A Netlify account (free at [netlify.com](https://netlify.com))
- Your Flutter app built for web (already done ✅)

## Option 1: Drag & Drop Deployment (Easiest)

1. **Build your web app** (if not already done):
   ```bash
   flutter build web --release
   ```

2. **Go to Netlify Dashboard**:
   - Visit [app.netlify.com](https://app.netlify.com)
   - Sign up or log in

3. **Deploy**:
   - On the main dashboard, find the **"Sites"** section
   - Look for **"Want to deploy a new site without connecting to Git? Drag and drop your site output folder here"**
   - Drag and drop the `build/web` folder from your project

4. **Your site is live!**
   - Netlify will automatically generate a URL like: `https://random-name-12345.netlify.app`
   - You can customize the site name in Site settings → General → Site details

## Option 2: Git-based Deployment (Recommended for Updates)

1. **Push your code to GitHub/GitLab/Bitbucket**

2. **Connect to Netlify**:
   - Go to [app.netlify.com](https://app.netlify.com)
   - Click **"Add new site"** → **"Import an existing project"**
   - Connect your Git provider and select your repository

3. **Configure build settings**:
   - **Build command**: `flutter build web --release`
   - **Publish directory**: `build/web`
   - Netlify will automatically detect the `netlify.toml` file if present

4. **Deploy**:
   - Click **"Deploy site"**
   - Netlify will build and deploy automatically
   - Every push to your main branch will trigger a new deployment

## Option 3: Netlify CLI (For Developers)

1. **Install Netlify CLI**:
   ```bash
   npm install -g netlify-cli
   ```

2. **Login**:
   ```bash
   netlify login
   ```

3. **Build and Deploy**:
   ```bash
   flutter build web --release
   netlify deploy --prod --dir=build/web
   ```

## Important Configuration

### Supabase CORS Settings

After deployment, you need to add your Netlify domain to Supabase:

1. Go to your **Supabase Dashboard**
2. Navigate to **Settings** → **API**
3. Under **"Allowed origins"**, add your Netlify URL:
   - Example: `https://your-site.netlify.app`
   - Also add: `https://your-site.netlify.app/*`

### Custom Domain (Optional)

1. In Netlify Dashboard → **Site settings** → **Domain management**
2. Click **"Add custom domain"**
3. Follow the instructions to configure your domain
4. Update Supabase CORS settings with your custom domain

## File Structure

The following files are already configured for Netlify:

- `netlify.toml` - Netlify build configuration
- `web/_redirects` - SPA routing support (ensures all routes work)

## Troubleshooting

### Build Fails
- Make sure Flutter is installed on Netlify's build environment
- Check the build logs in Netlify dashboard

### Routes Not Working
- The `web/_redirects` file should handle this
- Make sure it's copied to `build/web/_redirects` during build

### CORS Errors
- Add your Netlify domain to Supabase allowed origins
- Check browser console for specific error messages

## Updating Your Site

### Manual Update (Drag & Drop)
1. Run `flutter build web --release`
2. Drag and drop the new `build/web` folder to Netlify

### Automatic Update (Git)
- Just push to your connected Git repository
- Netlify will automatically rebuild and deploy

## Your Live URL

Once deployed, your app will be accessible at:
- **Netlify URL**: `https://your-site-name.netlify.app`
- **Custom Domain** (if configured): `https://yourdomain.com`

Share this URL with anyone who needs access to your app!

## Features That Work on Web

✅ Authentication (Supabase)
✅ Employee Dashboard
✅ Admin Dashboard  
✅ Task Management
✅ Messages
✅ Reports (Excel/PDF export)
✅ Dark/Light Theme
✅ Real-time Updates

## Features Limited on Web

⚠️ **Location Services**: Uses browser geolocation API (requires user permission)
⚠️ **Notifications**: Uses browser notifications API (requires user permission)
⚠️ **Camera**: Uses browser camera API (requires user permission)
⚠️ **Biometric Auth**: Not available on web

All core features work perfectly on web! 🎉

