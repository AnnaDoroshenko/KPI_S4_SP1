set projectName=lab2
D:\Programs\masm32\bin\ml.exe /c /Cx /Zd /coff %projectName%.asm 
D:\Programs\masm32\bin\link.exe /SUBSYSTEM:CONSOLE %projectName%.obj /OUT:%projectName%.exe
%projectName%.exe