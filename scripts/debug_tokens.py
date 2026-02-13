from supabase import create_client, Client

# Config from your existing script
URL = "https://bqjrdyxmcsbmiktwpukm.supabase.co"
KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJxanJkeXhtY3NibWlrdHdwdWttIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM2NjE0MjMsImV4cCI6MjA3OTIzNzQyM30.77EjEPgCfWT9S75ynNUc-UHmUhH6JcDFexE272qxvfo"

def main():
    print("--- DEBUGGING SUPABASE TOKENS ---")
    try:
        supabase: Client = create_client(URL, KEY)
        
        # 1. Check if column exists by selecting it (limit 1)
        print("1. Testing 'fcm_token' column existence...")
        try:
            resp = supabase.table("profiles").select("id, name, fcm_token").limit(5).execute()
            print("   [OK] Query successful.")
            
            rows = resp.data
            print(f"   found {len(rows)} profiles.")
            for row in rows:
                token = row.get('fcm_token')
                token_preview = f"{token[:10]}..." if token else "None"
                print(f"   - User: {row.get('name')} | Token: {token_preview}")
                
        except Exception as query_err:
            print(f"   [X] Query failed. Column might be missing or RLS error. \n   Error: {query_err}")

    except Exception as e:
        print(f"[X] Connection failed: {e}")

if __name__ == "__main__":
    main()
