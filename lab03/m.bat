set projectName=lab3
set moduleName=module
D:\Programs\masm32\bin\ml.exe /c /Cx /Zd /coff %projectName%.asm 
D:\Programs\masm32\bin\ml.exe /c /Cx /Zd /coff %moduleName%.asm 
D:\Programs\masm32\bin\link.exe /SUBSYSTEM:CONSOLE %projectName%.obj %moduleName%.obj /OUT:%projectName%.exe
%projectName%.exe