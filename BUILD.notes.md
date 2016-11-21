# Some personal build notes

## Using
* Cygwin
* Visual Studio 2015

## Steps so far in **tclparser**

* Add the following line to **Cygwin.bat**
```cmd
 call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" x86_amd64
```
* Add Tcl to your PATH in **Cygwin console**
```bash
PATH=/cygdrive/c/Program\ Files/Tcl/bin/:$PATH
```

* Rerun configure to update the old configure Files
```bash
./configure --with-tcl=/cygdrive/c/Dev/TclTk/tcl/win/Release_AMD64_VC10/
```

* Try make with failure
```bash
make
```
