import os
from google.oauth2.service_account import Credentials
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

SCOPES = ['https://www.googleapis.com/auth/drive']

class GoogleDriveService:
    def __init__(self, credentials_file: str, folder_id: str):
        self.credentials_file = credentials_file
        self.folder_id = folder_id
        
        # Load credentials
        try:
            self.credentials = Credentials.from_service_account_file(
                self.credentials_file, scopes=SCOPES)
            self.service = build('drive', 'v3', credentials=self.credentials)
        except Exception as e:
            raise Exception(f"Failed to load Drive Service at {self.credentials_file}: {e}")

    def upload_file(self, file_path: str, file_name: str, mime_type: str = 'video/mp4') -> str:
        """
        Uploads a file to Google Drive and returns the webViewLink (public link).
        """
        if not self.service:
            raise Exception("Google Drive Service is not authenticated.")

        file_metadata = {
            'name': file_name,
            'parents': [self.folder_id]
        }
        media = MediaFileUpload(file_path, mimetype=mime_type, resumable=True)

        # Upload the file
        file = self.service.files().create(
            body=file_metadata,
            media_body=media,
            fields='id, webViewLink'
        ).execute()

        file_id = file.get('id')
        
        # Make it public so anyone with the link can view it
        self.service.permissions().create(
            fileId=file_id,
            body={'type': 'anyone', 'role': 'reader'},
            fields='id'
        ).execute()

        return file.get('webViewLink')
