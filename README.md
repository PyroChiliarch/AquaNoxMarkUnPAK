# AquaNoxMarkUnPAK
.pak Unpacker for Aquanox, Aquanox 2: Revelation, Aquamark 3<br>
Enables viewing of Aquanox source files

![image](https://user-images.githubusercontent.com/11240849/193986707-fb15bd09-f2e1-46b0-8c0d-0dc5785b76c0.png)

Original source code location: https://www.moddb.com/games/aquanox/downloads/aquanox-1-2-modding-tools<br>

Original Authors:
v1.0: jTommy
v1.1 Update: CTPAX-X Team

Download (v1.1) from moddb has the following issues:
 - Source no longer builds in the current Delphi IDE
 - Included binary is detected as a virus by multiple AVs including Windows Defender
 
Version v1.2 changes:
 - Source will now build in Delphi IDE Community v10.4
 - Compiled binary no longer triggers windows defender
 
 Notes:<br>
Compiled binary will still trigger a small number of AVs on virustotal.<br>
From what I can tell this is caused by some kind of analytics gathering included in the executable when built by the official Delphi IDE.<br>
If this concerns you then I suggest building the Binary from source yourself using the official IDE (https://www.embarcadero.com/products/delphi/starter/free-download)<br>

I also plan on recreating this tool in C# which should remove this issue.
