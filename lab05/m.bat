set projectName=lab05
set moduleName=module
set moduleName1=longop
D:\Programs\masm32\bin\ml.exe /c /Cx /Zd /coff %projectName%.asm 
D:\Programs\masm32\bin\ml.exe /c /Cx /Zd /coff %moduleName%.asm %moduleName1%.asm
D:\Programs\masm32\bin\link.exe /SUBSYSTEM:CONSOLE %projectName%.obj %moduleName%.obj %moduleName1%.obj /OUT:%projectName%.exe
%projectName%.exe