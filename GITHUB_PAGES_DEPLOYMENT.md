# GitHub Pages Deployment Guide

This guide will help you deploy your BRAANDINS Flutter web app to GitHub Pages.

## Prerequisites

1.  **Git installed** on your computer.
2.  A **GitHub Account**.

---

## Step 1: Setup Git (If not already done)

Since your project is not yet a git repository, let's set it up.

1.  **Open your terminal** in the project folder (`c:\Subham\aiappsnew\braand-in_out\braand_app`).
2.  **Initialize Git**:
    ```bash
    git init
    git add .
    git commit -m "Initial commit of BRAANDINS app"
    ```
3.  **Create a Repository on GitHub**:
    - Go to [github.com/new](https://github.com/new).
    - Name it `braandins-app` (or whatever you like).
    - **Important**: Make it **Public** (Free GitHub Pages) or **Private** (requires Pro).
    - Do **not** add README, .gitignore, or license (we have them).
    - Click **Create repository**.

4.  **Link your local folder to GitHub**:
    - Copy the commands shown on GitHub under "…or push an existing repository from the command line".
    - It basically looks like this (replace `YOUR_USERNAME`):
      ```bash
      git remote add origin https://github.com/YOUR_USERNAME/braandins-app.git
      git branch -M main
      git push -u origin main
      ```

---

## Step 2: Deploy to GitHub Pages (The Easy Way)

We will use a tool called `peanut` which builds your Flutter app specifically for GitHub Pages and pushes it to a deployment branch automatically.

1.  **Install Peanut**:
    ```bash
    dart pub global activate peanut
    ```
    *(Note: You might need to add dart to your path, or run it via `flutter pub global run peanut` if that fails).*

2.  **Run the Deploy Build**:
    - **Scenario A: Project Page** (e.g., `username.github.io/repo-name/`)
      This is the most common. Run this command, replacing `repo-name` with your actual repository name on GitHub.
      ```bash
      flutter pub global run peanut --web-renderer canvaskit --extra-args "--base-href=/repo-name/"
      ```
    
    - **Scenario B: User Page** (e.g., `username.github.io` root domain)
      If your repo is named `username.github.io`, just run:
      ```bash
      flutter pub global run peanut --web-renderer canvaskit
      ```

3.  **Push the Deployment**:
    Peanut creates a special branch called `gh-pages` locally. You need to push it.
    ```bash
    git push origin --set-upstream gh-pages --force
    ```

---

## Step 3: Activate GitHub Pages

1.  Go to your Repository on **GitHub**.
2.  Click **Settings** (top right tab).
3.  On the left sidebar, click **Pages**.
4.  Under **Build and deployment** > **Source**, select **Deploy from a branch**.
5.  Under **Branch**, select `gh-pages` and folder `/ (root)`.
6.  Click **Save**.

## Step 4: Verify

- Wait about 1-2 minutes.
- Refresh the Pages settings page.
- You will see a banner at the top: **"Your site is live at https://..."**
- Click that link to tested your app!

---

## Troubleshooting

### "404 Not Found" on Refresh
GitHub Pages (like Netlify) doesn't naturally support Single Page Apps (SPA).
To fix this, we need to copy `index.html` to `404.html` so GitHub serves the app instead of an error page.

**Fix:**
This is usually handled automatically if you use the `peanut` tool? No, you might need to manually add a script or simple hack.
The easiest fix is to include the `build_runner` or just:
1. After running `peanut`, checkout the branch: `git checkout gh-pages`
2. Copy `index.html` to `404.html`.
3. Commit and push.

*Alternatively, the Drag & Drop method to Netlify/Cloudflare avoids this because they are smarter about SPAs.*

### Images not loading
Make sure you used the correct `--base-href`.
- If your URL is `user.github.io/my-app/`, your base-href must be `/my-app/`.
- If you forgot the leading or trailing slash, it will break.

---

## Summary Command List (for updates)

Every time you want to update your live site:

```bash
# 1. Save your code changes
git add .
git commit -m "Update app"
git push origin main

# 2. Re-deploy
flutter pub global run peanut --extra-args "--base-href=/YOUR_REPO_NAME/"
git push origin gh-pages --force
```
