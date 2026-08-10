import sys
import os
from google.oauth2.service_account import Credentials
from googleapiclient.discovery import build

SCOPES = ['https://www.googleapis.com/auth/drive']

def create_shared_folder():
    try:
        credentials = Credentials.from_service_account_file(
            'google_drive_credentials.json', scopes=SCOPES)
        service = build('drive', 'v3', credentials=credentials)
        
        file_metadata = {
            'name': 'POD_Videos',
            'mimeType': 'application/vnd.google-apps.folder'
        }
        
        # Create folder
        folder = service.files().create(body=file_metadata, fields='id').execute()
        
        folder_id = folder.get('id')
        print(f"FOLDER_ID={folder_id}")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    create_shared_folder()
