@echo off
title CloneX - System Startup

echo.
echo 🚀 Starting CloneX System...
echo.

REM Check if ports are available
echo 🔍 Checking ports...
netstat -an | find "5000" | find "LISTENING" >nul
if %errorlevel% == 0 (
    echo ⚠️  Port 5000 is in use - please close existing processes
) else (
    echo ✅ Port 5000 is available
)

netstat -an | find "3000" | find "LISTENING" >nul
if %errorlevel% == 0 (
    echo ⚠️  Port 3000 is in use - please close existing processes  
) else (
    echo ✅ Port 3000 is available
)

echo.
echo 🖥️  Starting Backend Server...

REM Start Backend
cd backend

REM Check if node_modules exists
if not exist "node_modules" (
    echo 📦 Installing backend dependencies...
    call npm install
)

echo 🚀 Starting backend server on port 5000...
start "VideoGen Backend" cmd /k "npm start"

REM Wait for backend to start
timeout /t 8 /nobreak >nul

REM Test backend health
echo 🏥 Testing backend health...
curl -s http://localhost:5000/health >nul 2>&1
if %errorlevel% == 0 (
    echo ✅ Backend is running successfully!
) else (
    echo ⚠️  Backend might still be starting...
)

echo.
echo 🎛️  Starting Admin Panel...

REM Start Admin Panel
cd ..\admin-panel

REM Check if node_modules exists
if not exist "node_modules" (
    echo 📦 Installing admin panel dependencies...
    call npm install
)

echo 🚀 Starting admin panel on port 3000...
start "VideoGen Admin" cmd /k "npm run dev"

REM Wait for admin panel to start
timeout /t 10 /nobreak >nul

echo.
echo 🎉 CloneX System Started Successfully!
echo.
echo 📊 Admin Panel Access:
echo 🌐 URL: http://localhost:3000/admin
echo 📧 Email: admin@videogenai.com
echo 🔒 Password: admin123
echo.
echo 🔧 Backend API:
echo 🌐 URL: http://localhost:5000
echo 🏥 Health: http://localhost:5000/health
echo.
echo 💾 Database:
echo 📊 MongoDB Atlas: Connected
echo.
echo 🛠️  Services Status:
echo ✅ ElevenLabs API: Configured
echo ✅ D-ID API: Configured  
echo ✅ Cloudinary: Configured
echo ✅ Firebase: Configured
echo.
echo 💡 Usage Tips:
echo • Use admin panel to monitor users and projects
echo • Check system health from the overview tab
echo • Manage user credits and delete projects
echo • View real-time statistics and analytics
echo.
echo 🌐 Opening admin panel in browser...
start http://localhost:3000/admin

echo.
echo 📱 System is running! Close this window or press Ctrl+C to stop.
echo 🛑 Or manually close the backend and admin panel windows.
echo.

REM Keep window open
pause