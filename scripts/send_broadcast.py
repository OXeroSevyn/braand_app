import os
from supabase import create_client, Client

# --- CONFIGURATION ---
URL = "https://bqjrdyxmcsbmiktwpukm.supabase.co"
# --- CONFIGURATION ---
URL = "https://bqjrdyxmcsbmiktwpukm.supabase.co"
# SERVICE ROLE KEY is required to bypass RLS for broadcasting
# Do NOT use the Anon key here.
SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

def main():
    print("--- Braand Custom Notification Broadcaster ---")
    print("This script sends a popup message to all active app users.")
    print("NOTE: You need the 'service_role' key to bypass RLS.")
    print("-" * 50)

    key = SERVICE_ROLE_KEY
    if not key:
        print("Env 'SUPABASE_SERVICE_KEY' not found.")
        key = input("Please enter your Supabase SERVICE_ROLE key: ").strip()

    try:
        supabase: Client = create_client(URL, key)
    except Exception as e:
        print(f"Error connecting to Supabase: {e}")
        print("Please ensure you have installed the client: pip install supabase")
        return


    while True:
        title = input("\nEnter Notification Title (or 'q' to quit): ").strip()
        if title.lower() == 'q':
            break
        
        message = input("Enter Notification Message: ").strip()
        if not title or not message:
            print("Error: Title and Message cannot be empty.")
            continue

        confirm = input(f"\nBroadcast '{title}: {message}' to ALL users? (y/n): ").lower()
        if confirm == 'y':
            try:
                data = {
                    "title": title,
                    "message": message,
                    # "created_at": is auto-handled by DB usually, or we can let Supabase handle it
                }
                # Insert into 'custom_notifications' table
                # We assume the table exists as per SupabaseService analysis
                supabase.table("custom_notifications").insert(data).execute()
                print("[OK] Notification Sent Successfully!")
            except Exception as e:
                print(f"[ERROR] Failed to send: {e}")
        else:
            print("Cancelled.")

if __name__ == "__main__":
    main()
