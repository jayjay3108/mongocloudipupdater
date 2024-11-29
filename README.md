# mongocloudipupdater
Updates the ip adress in Network Access List for cloud.mongodb.com
---
Steps to run:

mongodb-migrate.bat:
1. Save it with a `.bat` extension (e.g., `mongodb-migrate.bat`)
2. Replace the placeholder values:
    - `PROJECT_ID`
    - `PUBLIC_API`
    - `MONGO_KEY`
    - `MONGODB_CONNECTION_STRING`
3. Ensure `migrate.exe` is in the same directory or update its path
4. Run the script with administrator privileges
---
migrate-mongodb.bat:
1. Save it with a `.bat` extension
2. Replace these placeholder values:
    - `PROJECT_ID` with your MongoDB Atlas project ID
    - `PUBLIC_API` with your public API key
    - `MONGO_KEY` with your private API key
    - `ALLOWED_IP` with the specific IP address you want to whitelist
    - `MONGODB_CONNECTION_STRING` with your MongoDB connection string
3. Ensure `migrate.exe` is in the same directory or update its path
4. Run the script
---
update-ip.yml:
1. Create a new repository on GitHub (if you don't already have one)
2. Create the workflow file at `.github/workflows/update-ip.yml` with the content above
3. Add these secrets in your GitHub repository settings:
    - `MONGODB_PROJECT_ID`: Your MongoDB Atlas Project ID
    - `MONGODB_PUBLIC_KEY`: Your MongoDB Atlas Public API Key
    - `MONGODB_PRIVATE_KEY`: Your MongoDB Atlas Private API Key
---
monitor-ip.ps1:
1. Save the script as `monitor-ip.ps1`
2. Replace these values at the top of the script:
    - `your-project-id` with your MongoDB Atlas Project ID
    - `your-public-key` with your MongoDB Public API Key
    - `your-private-key` with your MongoDB Private API Key
3. Run the script as administrator once to set up:
powershell.exe -ExecutionPolicy Bypass -File "C:\\path\\to\\monitor-ip.ps1"
