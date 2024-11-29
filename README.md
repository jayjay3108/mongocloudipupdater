# mongocloudipupdater
Updates the ip adress in Network Access List for cloud.mongodb.com

---

Steps to run:

---

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
---
1. Save it as `monitor-ip.ps1`
2. Replace these values at the top:
    - `your-project-id` with MongoDB Atlas Project ID
    - `your-public-key` with MongoDB Public API Key
    - `your-private-key` with MongoDB Private API Key
    - Optionally change the `$LOCATION` variable to your preferred location identifier
3. Run as administrator:
powershell.exe -ExecutionPolicy Bypass -File "C:\\path\\to\\monitor-ip.ps1"

---
---

Description of the scripts:

---

mongodb-migrate.bat:
This Windows Batch script accomplishes the same tasks as your original script but with several improvements:

1. Uses native Windows commands and PowerShell where needed
2. Includes proper error handling
3. Uses Base64 encoding for authentication headers
4. Maintains the same workflow:
    - Gets the current public IP
    - Adds IP to MongoDB Atlas whitelist
    - Runs migrations
    - Removes IP from whitelist
    - Includes cleanup even if migration fails

---

migrate-mongodb.bat:
This simplified script:

1. Removes all runner-related code
2. Allows you to manually specify the IP address you want to add to MongoDB Atlas Network Access
3. Doesn't remove the IP after migration (since it's a permanently allowed IP)
4. Still maintains the core functionality of:
    - Adding IP to MongoDB Atlas whitelist
    - Running migrations

---

update-ip.yml:
This solution:

1. Creates a GitHub Actions workflow that runs every 30 minutes (configurable)
2. Checks your current public IP using [api.ipify.org](http://api.ipify.org/)
3. Only updates MongoDB Atlas Network Access if the IP has changed
4. Stores the last known IP in a file for comparison
5. Uses GitHub's secure secrets for storing sensitive MongoDB credentials

The workflow will:

- Run automatically every 30 minutes
- Check if your IP has changed
- Update MongoDB Atlas Network Access only when necessary
- Keep a record of your last IP in the repository
- Can be manually triggered from the GitHub Actions tab if needed

Benefits of this approach:

1. No need for a local runner
2. Runs on GitHub's infrastructure
3. Automatic and reliable monitoring
4. Secure credential handling
5. Easy to monitor through GitHub Actions dashboard
6. Maintains history of IP changes through git commits

---

monitor-ip.ps1:
This solution:

1. Runs locally on your Windows machine
2. Creates a Windows Scheduled Task that runs every 15 minutes
3. Checks your actual home IP address
4. Updates MongoDB Atlas only when your IP changes
5. Maintains logs in `C:\\MongoIPMonitor\\ip-monitor.log`
6. Stores the last known IP in `C:\\MongoIPMonitor\\last-ip.txt`
7. Runs automatically after system restart
8. Uses Windows Task Scheduler for reliability

The script will:

- Monitor your home IP address every 15 minutes
- Update MongoDB Atlas Network Access when your IP changes
- Log all activities for troubleshooting
- Run automatically in the background
- Start automatically when Windows starts

---

ip-monitor.ps1:
Key changes made:

1. Added more context to the MongoDB Network Access comment including:
    - Location identifier (configurable at the top of script)
    - Computer name
    - Username
    - Timestamp
2. The comment will now appear in MongoDB like this example:
`"Auto-updated: Home | PC: DESKTOP-ABC123 | User: John | Updated: 2024-11-29 14:30:00"`

The script will now add detailed comments to your MongoDB Network Access entries, making it easier to:

- Track which computer updated the IP
- Know when the IP was last updated
- Identify who was using the computer
- Distinguish between different locations if you use the script on multiple machines
