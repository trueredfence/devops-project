#!/usr/bin/python3

#pip install google-auth google-auth-oauthlib
#download cred json file form google developer console
from google_auth_oauthlib.flow import InstalledAppFlow
SCOPES = ['https://www.googleapis.com/auth/drive']
flow = InstalledAppFlow.from_client_secrets_file('cred.json', SCOPES)
credentials = flow.run_local_server(port=0)
print("Refresh Token:", credentials.refresh_token)
