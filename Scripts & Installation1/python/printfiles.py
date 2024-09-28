#!/usr/bin/python3
# Need to add scope and refresh token in cred file as formated cred.json
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
credentials = Credentials.from_authorized_user_file('cred.json')
drive_service = build('drive', 'v3', credentials=credentials)

try:
    # Attempt to retrieve the list of files from Google Drive
    results = drive_service.files().list(pageSize=10).execute()
    items = results.get('files', [])

    if not items:
        print("No files found.")
    else:
        print("Files:")
        for item in items:
            print(f"{item['name']} ({item['id']})")

except Exception as e:
    print("An error occurred:", e)