@echo off
curl -X POST -F "file=@C:\Users\miyuj\Desktop\logput\edit.txt" http://localhost:8080/MyApp/uploadF?folder=text

pause