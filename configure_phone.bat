@echo off
echo ========================================
echo Configuration Backend pour Telephone
echo ========================================
echo.

echo Etape 1: Trouver votre adresse IP...
echo.
ipconfig | findstr /i "IPv4"
echo.

echo Etape 2: Notez votre adresse IP (ex: 192.168.1.100)
echo.

set /p IP="Entrez votre adresse IP: "

echo.
echo ========================================
echo Configuration terminee!
echo ========================================
echo.
echo Votre configuration:
echo - API URL: http://%IP%:8000/api
echo - WebSocket URL: ws://%IP%:8080
echo.
echo Prochaines etapes:
echo 1. Ouvrez lib/utils/constants.dart
echo 2. Remplacez les URLs par celles ci-dessus
echo 3. Demarrez les serveurs:
echo    - Terminal 1: cd backend/api ^&^& php -S 0.0.0.0:8000
echo    - Terminal 2: cd backend ^&^& php websocket_server.php
echo 4. Lancez l'app: flutter run
echo.
pause
