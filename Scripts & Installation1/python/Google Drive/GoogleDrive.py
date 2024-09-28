#!/usr/bin/python3
#  pip install google-auth google-auth-oauthlib google-api-python-client
# Need to add scope and refresh token in cred file as formated cred.json
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
import io
import os
from googleapiclient.http import MediaIoBaseDownload
DATA_FOLDER = 'Data/'
CRED = '\033[91m'
CEND = '\033[0m'
CGREEN = '\033[92m'

credentials = Credentials(
    client_id ="",
    # project_id ="abctest-397515",
    # auth_uri ="https://accounts.google.com/o/oauth2/auth",
    token_uri ="https://oauth2.googleapis.com/token",
    # auth_provider_x509_cert_url ="https://www.googleapis.com/oauth2/v1/certs",
    client_secret ="",
    # redirect_uris =["http://localhost"], 
    refresh_token ="", 
    scopes = ["https://www.googleapis.com/auth/drive"],
    token = "null"
)

# credentials = Credentials.from_authorized_user_file('cred.json')
drive_service = build('drive', 'v3', credentials=credentials)
#download_location = input("Enter the download location (including filename): ")
machine_name = input("Enter Machine/Bot Name : ")
download_path = os.path.join(DATA_FOLDER, machine_name)

try:
    # Attempt to retrieve the list of files from Google Drive
    results = drive_service.files().list(pageSize=100).execute()
    items = results.get('files', [])

    if not items:
        print(CRED+"'No files found"+CEND)
    else:  
        if not os.path.exists(download_path):os.makedirs(download_path)
        print(CGREEN+machine_name+" created in Data folder."+CEND)   
        for item in items:
            file_name = item['name'];
            dloc = os.path.join(download_path, file_name)
            response = drive_service.files().list(q=f"name='{item['name']}'").execute()
            files = response.get('files', [])
            file_to_download = files[0]
            # Download the file
            if 'mimeType' in file_to_download and file_to_download['mimeType'].startswith('application/vnd.google-apps'):
                # Export Google Docs Editors file
                export_mime_type = 'application/pdf'  # Change this to your desired export format
                request = drive_service.files().export_media(fileId=file_to_download['id'], mimeType=export_mime_type)
                with open(f'{dloc}.{export_mime_type.split("/")[-1]}', 'wb') as f:
                # with open(dloc, 'wb') as f:
                    downloader = MediaIoBaseDownload(f, request)
                    done = False
                    while done is False:
                        status, done = downloader.next_chunk()

                print(CGREEN+file_name+" exported and downloaded."+CEND)

            else:
                # Download other file types
                request = drive_service.files().get_media(fileId=file_to_download['id'])
                file_io = io.BytesIO()
                downloader = MediaIoBaseDownload(file_io, request)
                done = False
                while done is False:
                    status, done = downloader.next_chunk()
                
                with open(dloc, 'wb') as f:
                    f.write(file_io.getvalue())

                print(CGREEN+file_name+" exported and downloaded."+CEND)

            # Delete the file
            drive_service.files().delete(fileId=file_to_download['id']).execute()
            print(CRED+file_name+" deleted from Drive."+CEND)
except Exception as e:
    print("An error occurred=", e)