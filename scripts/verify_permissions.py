import os
from supabase import create_client, Client

# --- CONFIGURATION ---
URL = "https://bqjrdyxmcsbmiktwpukm.supabase.co"
# We need the SERVICE ROLE KEY to inspect the DB freely, or we can test with ANON key to see what's blocked.
# Let's use the key provided by the user for the "Admin" check, simulating a privileged environment
# BUT to test RLS, we should really login as a user. 
# For now, let's just check if we can read profiles using the Service Role Key, 
# which confirms connection and basic table existence.
SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

def main():
    print("--- Braand Permissions Verifier ---")
    
    key = SERVICE_ROLE_KEY
    if not key:
        key = input("Enter Supabase SERVICE_ROLE key: ").strip()

    try:
        supabase: Client = create_client(URL, key)
    except Exception as e:
        print(f"[ERROR] Connection failed: {e}")
        return

    print("\n[1] Checking 'profiles' table existence and count...")
    try:
        response = supabase.table("profiles").select("id, role, name", count="exact").execute()
        print(f"    [OK] Found {response.count} profiles.")
        
        admins = [p for p in response.data if p.get('role') == 'Admin']
        print(f"    [OK] Found {len(admins)} Admins.")
        for admin in admins:
            print(f"         - {admin.get('name')} (ID: {admin.get('id')})")
            
    except Exception as e:
        print(f"    [ERROR] Failed to query profiles: {e}")

    print("\n[2] Checking 'custom_notifications' table...")
    try:
        response = supabase.table("custom_notifications").select("*", count="exact").execute()
        print(f"    [OK] Found {response.count} notifications.")
    except Exception as e:
        print(f"    [ERROR] Failed to query notifications: {e}")

if __name__ == "__main__":
    main()
