
import firebase_admin
from firebase_admin import credentials, messaging
from supabase import create_client, Client
import os

# --- CONFIGURATION ---
# Supabase Credentials (Same as in app)
SUPABASE_URL = "https://bqjrdyxmcsbmiktwpukm.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJxanJkeXhtY3NibWlrdHdwdWttIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM2NjE0MjMsImV4cCI6MjA3OTIzNzQyM30.77EjEPgCfWT9S75ynNUc-UHmUhH6JcDFexE272qxvfo"

# Firebase Service Account Key Path
# YOU MUST DOWNLOAD THIS FROM FIREBASE CONSOLE:
# Project Settings > Service accounts > Generate new private key
# Project Settings > Service accounts > Generate new private key
SERVICE_ACCOUNT_KEY_PATH = os.path.join(os.path.dirname(__file__), "serviceAccountKey.json")


def init_firebase():
    try:
        cred = credentials.Certificate(SERVICE_ACCOUNT_KEY_PATH)
        firebase_admin.initialize_app(cred)
        print("🔥 Firebase Admin Initialized")
    except Exception as e:
        print(f"❌ Error initializing Firebase: {e}")
        print(f"Make sure you have downloaded '{SERVICE_ACCOUNT_KEY_PATH}' from Firebase Console.")
        return False
    return True

def get_tokens():
    try:
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
        
        # Call the secure RPC function to bypass RLS
        response = supabase.rpc('get_fcm_tokens', {}).execute()
        
        # Response data is a list of dicts: [{'fcm_token': '...'}, ...]
        if not response.data:
            return []
            
        tokens = [row['fcm_token'] for row in response.data if row.get('fcm_token')]
        return list(set(tokens))
    except Exception as e:
        print(f"❌ Error fetching tokens from Supabase: {e}")
        return []

def send_broadcast(title, body, tokens):
    if not tokens:
        print("⚠️ No devices found to send to.")
        return

    message = messaging.MulticastMessage(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        data={
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "screen": "dashboard", 
            "status": "done"
        },
        tokens=tokens,
    )

    try:
        # send_multicast is deprecated/removed in newer versions, use send_each_for_multicast
        response = messaging.send_each_for_multicast(message)
        print(f"✅ Successfully sent {response.success_count} messages.")
        if response.failure_count > 0:
            print(f"⚠️ Failed to send {response.failure_count} messages.")
            for idx, resp in enumerate(response.responses):
                if not resp.success:
                    print(f"   - Error: {resp.exception}")
    except Exception as e:
        print(f"❌ Error sending broadcast: {e}")

def main():
    print("--- Braand FCM Broadcast System ---")
    
    if not os.path.exists(SERVICE_ACCOUNT_KEY_PATH):
        print(f"❌ ERROR: '{SERVICE_ACCOUNT_KEY_PATH}' not found!")
        print("Please download it from: Firebase Console > Project Settings > Service accounts > Generate new private key")
        return

    if not init_firebase():
        return

    while True:
        print("\n--- New Broadcast ---")
        title = input("Title (or 'q' to quit): ").strip()
        if title.lower() == 'q':
            break
        
        body = input("Message: ").strip()
        if not title or not body:
            print("Error: content cannot be empty.")
            continue

        print("Fetching tokens...")
        tokens = get_tokens()
        print(f"Found {len(tokens)} active devices.")

        if len(tokens) > 0:
            confirm = input(f"Send '{title}: {body}' to {len(tokens)} devices? (y/n): ").lower()
            if confirm == 'y':
                send_broadcast(title, body, tokens)
            else:
                print("Cancelled.")
        else:
            print("No users have registered devices yet.")

if __name__ == "__main__":
    main()
