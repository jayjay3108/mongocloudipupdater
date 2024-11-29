@echo off
setlocal EnableDelayedExpansion

:: Set your MongoDB Atlas credentials
set "PROJECT_ID=myproject"
set "PUBLIC_API=mongo-public-api-key"
set "MONGO_KEY=mongo-private-api-key"

:: Get public IP address
for /f "tokens=*" %%a in ('powershell -Command "(Invoke-WebRequest -Uri 'https://api.ipify.org').Content"') do set "IP_ADDRESS=%%a"
echo Current IP: %IP_ADDRESS%

:: Create JSON data for IP whitelist
set "JSON_DATA=[{\"ipAddress\": \"%IP_ADDRESS%\", \"comment\": \"Windows Migration Script\"}]"

:: Set API URLs
set "URL=https://cloud.mongodb.com/api/atlas/v1.0/groups/%PROJECT_ID%/accessList"
set "URL_DELETE=https://cloud.mongodb.com/api/atlas/v1.0/groups/%PROJECT_ID%/accessList/%IP_ADDRESS%%%2F32"

:: Create Base64 encoded credentials
for /f "tokens=*" %%a in ('powershell -Command "[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(\"%PUBLIC_API%:%MONGO_KEY%\"))"') do set "AUTH_HEADER=%%a"

:: Add IP to whitelist
echo Adding IP to whitelist...
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
    goto cleanup
)

:cleanup
:: Remove IP from whitelist
echo Removing IP from whitelist...
powershell -Command "& {$headers = @{'Authorization'='Basic %AUTH_HEADER%'}; Invoke-RestMethod -Uri '%URL_DELETE%' -Method Delete -Headers $headers}"

if %ERRORLEVEL% neq 0 (
    echo Failed to remove IP from whitelist
    exit /b 1
)

echo Migration completed successfully
exit /b 0
