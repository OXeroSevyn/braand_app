import os
from supabase import create_client, Client

# --- CONFIGURATION ---
URL = "https://bqjrdyxmcsbmiktwpukm.supabase.co"
KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJxanJkeXhtY3NibWlrdHdwdWttIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM2NjE0MjMsImV4cCI6MjA3OTIzNzQyM30.77EjEPgCfWT9S75ynNUc-UHmUhH6JcDFexE272qxvfo"

def main():
    print("--- Braand Custom Notification Broadcaster ---")
    print("This script sends a popup message to all active app users.")
    print("-" * 50)

    try:
        supabase: Client = create_client(URL, KEY)
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
                result = supabase.table("custom_notifications").insert(data).execute()
                print("✅ Notification Sent Successfully!")
            except Exception as e:
                print(f"❌ Failed to send: {e}")
        else:
            print("Cancelled.")

if __name__ == "__main__":
    main()
