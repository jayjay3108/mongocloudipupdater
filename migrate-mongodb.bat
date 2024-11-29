@echo off
setlocal EnableDelayedExpansion

:: Set your MongoDB Atlas credentials
set "PROJECT_ID=myproject"
set "PUBLIC_API=mongo-public-api-key"
set "MONGO_KEY=mongo-private-api-key"
:: Set the specific IP you want to whitelist
set "ALLOWED_IP=YOUR_IP_ADDRESS"

:: Create JSON data for IP whitelist
set "JSON_DATA=[{\"ipAddress\": \"%ALLOWED_IP%\", \"comment\": \"Migration Script Access\"}]"

:: Set API URL
set "URL=https://cloud.mongodb.com/api/atlas/v1.0/groups/%PROJECT_ID%/accessList"

:: Create Base64 encoded credentials
for /f "tokens=*" %%a in ('powershell -Command "[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(\"%PUBLIC_API%:%MONGO_KEY%\"))"') do set "AUTH_HEADER=%%a"

:: Add IP to whitelist
echo Adding IP %ALLOWED_IP% to MongoDB Atlas Network Access...
powershell -Command "& {$headers = @{'Authorization'='Basic %AUTH_HEADER%'; 'Content-Type'='application/json'}; $body = '%JSON_DATA%'; Invoke-RestMethod -Uri '%URL%' -Method Post -Headers $headers -Body $body}"

if %ERRORLEVEL% neq 0 (
    echo Failed to add IP to whitelist
    exit /b 1
)

:: Run migration
echo Running migration scripts...
migrate.exe -path migrations -database "%MONGODB_CONNECTION_STRING%" up

if %ERRORLEVEL% neq 0 (
    echo Migration failed
    exit /b 1
)

echo Migration completed successfully
exit /b 0
