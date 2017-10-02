
#import "Basic";
#import "Compiler";
#import "File";
#import "File_Utilities";

setup_build :: () -> Build_Options {
    options := get_build_options();
    set_optimization_level(*options, 0, 0);
    options.backend = Backend.X64;
    options.llvm_options.enable_split_modules = false;

    options.output_type = Build_Output_Type.NO_OUTPUT;
    options.output_executable_name = "";
    options.output_path = concatenate(#filepath, "../run_tree/");
    make_directory_if_it_does_not_exist(options.output_path);
    
    set_build_options(options);

    stb_src := C_compiler_make_source_file("src/stb.cpp");
    miniz_src := C_compiler_make_source_file("src/miniz.c");
    // compile stb lib
     #if OS_WINDOWS {
        stb_lib := C_compiler_make_lib("run_tree/stb.dll", true, stb_src);
        miniz_lib := C_compiler_make_lib("run_tree/miniz.dll", true, miniz_src);
    } else {
        stb_lib := C_compiler_make_lib("run_tree/libstb.so", true, stb_src);
        miniz_lib := C_compiler_make_lib("run_tree/libminiz.so", true, miniz_src);

        stb_stat := C_compiler_make_lib("run_tree/libstb.a", false,  C_compiler_make_object("run_tree/stb.o", stb_src));
        miniz_stat := C_compiler_make_lib("run_tree/libminiz.a", false, C_compiler_make_object("run_tree/miniz.o", miniz_src));
        C_compiler_build_target(<< stb_stat);
        C_compiler_build_target(<< miniz_stat);
    }

    C_compiler_build_target(<< stb_lib);
    C_compiler_build_target(<< miniz_lib);

    compiler_add_library_search_directory(options.output_path);

    return options;
};

build_workspace :: (name: string) -> Workspace, Build_Options {
    options := setup_build();
    options.output_type = Build_Output_Type.EXECUTABLE;
    options.output_executable_name = name;
    
    w := compiler_create_workspace(name);
    set_build_file_path(#filepath, w);
    set_build_options(options, w);
    return w, options;
}

build_debug :: () -> Workspace, Build_Options {
    w, options := build_workspace("renderer");
    add_build_file("main.jai", w);

    #if OS_WINDOWS {
        add_build_file("os_windows.jai", w);
    } else {
        add_build_file("os_linux.jai", w);
    }

    add_build_string("DEBUG :: true;", w);
    add_build_string("DEVELOPER :: true;", w);
    return w, options;
}

demo :: () {
    w, options := build_debug();
    options.output_type = Build_Output_Type.NO_OUTPUT;
    set_build_options(options, w);
    add_build_string("#run main();", w);
}

#run build_debug();
// #run demo();
// #run {
//     setup_build();
//     return;
// };

// C compilation code

C_Output_Type :: enum {
    NO_OUTPUT,
    COPY_FILE,
    EXECUTABLE,
    OBJECT,
    STATIC_LIBRARY,
    DYNAMIC_LIBRARY,
}

C_Target :: struct {
    output_type: C_Output_Type;
    output_path: string; // output file path
    dependencies: [..] *C_Target;

    // for executable/dynamic libs
    libs: [..] string;
}

#if OS_WINDOWS {

C_LIB_MATH :: ""; // cl seems to link in the math lib by default

COMPILER_FLAG_PIC_STRING :: "";
COMPILER_STRING_OBJ :: "cl /nologo /INCREMENTAL:NO /c /Fo:";
COMPILER_STRING_DLL :: "cl /nologo /INCREMENTAL:NO /LD /Fe:";
COMPILER_STRING_STATIC :: "ar rcs ";

get_file_timestamp :: (path: string) -> u64 {
    ft: FILETIME;
    file, success := file_open(path);
    if (!success) {
        return 0;
    }
    GetFileTime(file.handle, null, null, *ft);
    file_close(*file);
    return (cast(u64) ft.dwLowDateTime) | ((cast(u64) ft.dwHighDateTime) << 32); 
}

}

#if OS_LINUX {

C_LIB_MATH :: "m";

COMPILER_FLAG_PIC_STRING :: "-fPIC";
COMPILER_STRING_OBJ :: "gcc -fno-exceptions -fno-rtti -c -o ";
COMPILER_STRING_DLL :: "gcc -fPIC -shared -o ";
COMPILER_STRING_STATIC :: "ar rcs ";

get_file_timestamp :: (path: string) -> u64 {
    p := to_c_string(path);
    defer free(p);
    st: stat_t;
    status := stat(p, *st);
    return xx st.st_mtime.tv_sec;
}

}

C_compiler_make_copy :: (out: string, in: *C_Target) -> *C_Target {
    target := New(C_Target);
    target.output_type = C_Output_Type.COPY_FILE;
    target.output_path = copy_string(out);

    array_add(*target.dependencies, in);
    return target;
}

C_compiler_make_source_file :: (filepath: string) -> *C_Target {
    target := New(C_Target);
    target.output_type = C_Output_Type.NO_OUTPUT;
    target.output_path = copy_string(filepath);
    return target;
}

C_compiler_make_object :: (output: string, inputs: .. *C_Target) -> *C_Target {
    target := New(C_Target);
    target.output_type = C_Output_Type.OBJECT;
    target.output_path = copy_string(output);

    for inputs {
        array_add(*target.dependencies, it);
    }

    return target;
}

C_compiler_add_lib :: (target: *C_Target, libname: string) {
    // @Robustness, check if lib exists, check if lib is already in list
    array_add(*target.libs, copy_string(libname));
}

C_compiler_make_lib :: (output: string, dynamic: bool, inputs: .. *C_Target) -> *C_Target {
    target := New(C_Target);
    if dynamic target.output_type = C_Output_Type.DYNAMIC_LIBRARY;
    else target.output_type = C_Output_Type.STATIC_LIBRARY;

    target.output_path = copy_string(output);

    for inputs {
        array_add(*target.dependencies, it);
    }

    return target;
}

C_compiler_is_target_outdated :: (target: C_Target) -> bool {
    target_time := get_file_timestamp(target.output_path);

    if (target_time == 0) return true;

    for target.dependencies {
        if (C_compiler_is_target_outdated(<< it)) return true;

        dep_time := get_file_timestamp(it.output_path);
        if (target_time <= dep_time) return true;
    }

    return false;
}

// builds the target and returns a path to its output
C_compiler_build_target :: (target: C_Target, flag_string: string = "") -> string {
    if (!C_compiler_is_target_outdated(target)) return target.output_path;

    print("Building %...\n", target.output_path);
    cmd_string: string;

    if target.output_type == {
        case C_Output_Type.NO_OUTPUT; // for hand written files (read: source files)
        case C_Output_Type.OBJECT;
            cmd_string = concatenate(COMPILER_STRING_OBJ, target.output_path, " ", flag_string, " ");
        case C_Output_Type.DYNAMIC_LIBRARY;
            cmd_string = concatenate(COMPILER_STRING_DLL, target.output_path, " ", flag_string, " ");
        case C_Output_Type.STATIC_LIBRARY;
            cmd_string = concatenate(COMPILER_STRING_STATIC, target.output_path, " ", flag_string, " ");
        case C_Output_Type.COPY_FILE;
            assert(target.dependencies.count == 1);
            in := target.dependencies[0];
            if copy_file(in.output_path, target.output_path)
                print("Copied % to %\n", in, target.output_path);
            else
                print("Error copying % to %\n", in, target.output_path);

            return target.output_path;
    }

    flags := "";
    if target.output_type == C_Output_Type.DYNAMIC_LIBRARY {
        flags = COMPILER_FLAG_PIC_STRING;
    }
    for target.dependencies {
        data := cmd_string.data;
        cmd_string = concatenate(cmd_string, C_compiler_build_target(<< it, flags), " ");
        if data free(data);
    }

    for target.libs {
        #if OS_LINUX {
            old := cmd_string.data;
            cmd_string = concatenate(cmd_string, "-l ", it, " ");
            if old free(old);
        }
    }

    if (cmd_string.count) {
        print("Running command: %\n", cmd_string);
        os_run_command(cmd_string);
        free(cmd_string.data);
    }

    print("Built %.\n", target.output_path);
    return target.output_path;
}
