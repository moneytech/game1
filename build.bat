
@set COMPILER_OPTIONS=/nologo /Zi /DDEBUG=1 /DWIN32
@cl %COMPILER_OPTIONS% src/build.cpp ^
	 /Fe:run_tree\renderer.exe opengl32.lib gdi32.lib user32.lib

rm *.obj *.pdb