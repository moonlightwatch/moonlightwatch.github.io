
Remove-Item * -Exclude *sources* -Recurse
Set-Location sources
Remove-Item public -Recurse
.\hugo.exe
Move-Item -Path .\public\* -Destination ..\
Set-Location ..
git add .
git commit -am "build"
git push
