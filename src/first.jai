
#import "Basic";
#import "Compiler";
#import "File";
#import "File_Utilities";
#import "String";

#if OS_WINDOWS {
    #import "Windows";
} else #if OS_LINUX {
    #import "POSIX";
    DLL_EXT :: ".so";
} else #if OS_MACOSX {
    #import "POSIX";
    DLL_EXT :: ".dylib";
}

ENGINE_SRC_PATH :: #filepath;
ENGINE_RUNTREE_PATH :: #run concatenate(ENGINE_SRC_PATH, "/../run_tree/");

make_directory_tree :: (_path: string) {
    path := _path;
    if path.count && path[path.count-1] == #char "/" {
        path.count -= 1;
    }

    base_name := basename(path);
    if base_name == "assets" return;

    parent := path_strip_filename(path);
    make_directory_tree(parent);
    make_directory_if_it_does_not_exist(path);
}

copy_engine_assets_to :: (path: string) {
    // @TODO maybe use the C-build file-copy system so we only do expensive copies
    // for files that have changed?
    engine_path := concatenate(#filepath, "../run_tree/assets");
    paths: [2] string;
    paths[0] = engine_path;
    paths[1] = path;

    visitor :: (info: *File_Visit_Info, paths: [2] string) {
        relative_path := info.full_name;
        advance(*relative_path, paths[0].count);
        out_path := concatenate(paths[1], "/", relative_path);
        // print("out: %\n", out_path);
        make_directory_tree(path_strip_filename(out_path));
        copy_file(info.full_name, out_path);
    }

    res := visit_files(engine_path, true, paths, visitor);
    assert(res);
}

setup_build :: (output_path: string) -> Build_Options {
    options := get_build_options();
    set_optimization_level(*options, 0, 0);
    options.backend = Backend.LLVM;
    options.llvm_options.enable_split_modules = false;

    options.output_type = Build_Output_Type.NO_OUTPUT;
    options.output_executable_name = "";
    options.output_path = output_path;
    make_directory_if_it_does_not_exist(options.output_path);
    
    set_build_options(options);

    // print("Output path: %\n", output_path);

    stb_src := C_compiler_make_source_file(concatenate(#filepath, "/stb.cpp"));
    miniz_src := C_compiler_make_source_file(concatenate(#filepath, "/miniz.c"));
    nuklear_src := C_compiler_make_source_file(concatenate(#filepath, "/nuklear.c"));
    // compile stb lib
     #if OS_WINDOWS {
        stb_lib := C_compiler_make_copy(concatenate(options.output_path, "/stb.dll"), C_compiler_make_lib(concatenate(ENGINE_RUNTREE_PATH, "/stb.dll"), true, stb_src));
        miniz_lib := C_compiler_make_copy(concatenate(options.output_path, "/miniz.dll"), C_compiler_make_lib(concatenate(ENGINE_RUNTREE_PATH, "/miniz.dll"), true, miniz_src));
        nuklear_lib := C_compiler_make_copy(concatenate(options.output_path, "/nuklear.dll"), C_compiler_make_lib(concatenate(ENGINE_RUNTREE_PATH, "/nuklear.dll"), true, nuklear_src));
    } else {
        stb_lib := C_compiler_make_copy(concatenate(options.output_path, "/stb"), C_compiler_make_lib(concatenate(ENGINE_RUNTREE_PATH, "/stb", DLL_EXT), true, stb_src));
        miniz_lib := C_compiler_make_copy(concatenate(options.output_path, "/miniz"), C_compiler_make_lib(concatenate(ENGINE_RUNTREE_PATH, "/miniz", DLL_EXT), true, miniz_src));
        nuklear_lib := C_compiler_make_copy(concatenate(options.output_path, "/nuklear"), C_compiler_make_lib(concatenate(ENGINE_RUNTREE_PATH, "/nuklear", DLL_EXT), true, nuklear_src));

        stb_stat := C_compiler_make_lib(concatenate(ENGINE_RUNTREE_PATH, "/stb.a"), false,  C_compiler_make_object(concatenate(options.output_path, "/stb.o"), stb_src));
        miniz_stat := C_compiler_make_lib(concatenate(ENGINE_RUNTREE_PATH, "/miniz.a"), false, C_compiler_make_object(concatenate(options.output_path, "/miniz.o"), miniz_src));
        nuklear_stat := C_compiler_make_lib(concatenate(ENGINE_RUNTREE_PATH, "/nuklear.a"), false, C_compiler_make_object(concatenate(options.output_path, "/nuklear.o"), nuklear_src));

        C_compiler_build_target(<< stb_stat);
        C_compiler_build_target(<< miniz_stat);
        C_compiler_build_target(<< nuklear_stat);
    }

    C_compiler_build_target(<< stb_lib);
    C_compiler_build_target(<< miniz_lib);
    C_compiler_build_target(<< nuklear_lib);

    // SUPPORTS_OCULUS @TODO
    #if false {
        copy_libovr := C_compiler_make_copy(concatenate(options.output_path, "/LibOVR_out.dll"), C_compiler_make_source_file(concatenate(ENGINE_RUNTREE_PATH, "/LibOVR_out.dll")));
        C_compiler_build_target(<< copy_libovr);
    }

    // compiler_add_library_search_directory(options.output_path);

    #if OS_MACOSX {
        process_start("install_name_tool -id \"@rpath/stb.dylib\" stb.dylib");
        process_start("install_name_tool -id \"@rpath/miniz.dylib\" miniz.dylib");
        process_start("install_name_tool -id \"@rpath/nuklear.dylib\" nuklear.dylib");
    }

    return options;
};

add_engine_to_workspace :: (w: Workspace) {
    add_build_file("physics.jai", w);
    add_build_file("renderer.jai", w);
    add_build_file("asset_manager.jai", w);
    add_build_file("FBX.jai", w);
    add_build_file("imgui.jai", w);
    add_build_file("os_api.jai", w);
    add_build_file("game.jai", w);
    add_build_file("nuklear.jai", w);
    add_build_file("math.jai", w);
}

build_workspace :: (name: string, output_path: string) -> Workspace, Build_Options {
    options := setup_build(output_path);
    options.output_type = Build_Output_Type.EXECUTABLE;
    options.output_executable_name = name;
    options.intermediate_path = concatenate(output_path, "../build");
    
    w := compiler_create_workspace(name);
    file_path := copy_string(#filepath);
    // print("file_path: %\n", file_path);
    set_build_file_path(file_path, w);
    set_build_options(options, w);
    return w, options;
}

build_debug :: () -> Workspace, Build_Options {
    w, options := build_workspace("renderer", concatenate(#filepath, "../run_tree/"));
    add_engine_to_workspace(w);
    add_build_file("main.jai", w);

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

// #run build_debug();
// #run demo();
// #run {
//     setup_build();
//     return;
// };

// C compilation code

C_Output_Type :: enum {
    NO_OUTPUT;
    COPY_FILE;
    EXECUTABLE;
    OBJECT;
    STATIC_LIBRARY;
    DYNAMIC_LIBRARY;
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

COMPILER_FLAG_PIC_STRING :: {:string:
    "",
};

COMPILER_STRING_OBJ :: {:string:
    "cl",
    "/nologo",
    "/INCREMENTAL:NO",
    "/DWINDOWS",
    "/Z7",
    "/c",
    "/Fo:",
};

COMPILER_STRING_DLL :: {:string:
    "cl",
    "/nologo",
    "/INCREMENTAL:NO",
    "/DWINDOWS",
    "/Z7",
    "/LD",
    "/Fe:",
};

COMPILER_STRING_STATIC :: {:string:
    "ar",
    "rcs",
};

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

#if OS_LINUX || OS_MACOSX {

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

#import "Process";

EMPTY_FLAGS :: {:string:
    "as",
};

// builds the target and returns a path to its output
C_compiler_build_target :: (target: C_Target, flag_string: ..string) -> string {
    if (!C_compiler_is_target_outdated(target)) return target.output_path;

    print("Building %...\n", target.output_path);
    cmd_strings: [..] string;

    if target.output_type == {
        case C_Output_Type.NO_OUTPUT; // for hand written files (read: source files)
        case C_Output_Type.OBJECT;
            // cmd_string = concatenate(COMPILER_STRING_OBJ, target.output_path, " ", flag_string, " ");
            array_append(*cmd_strings, ..COMPILER_STRING_OBJ);
            array_add(*cmd_strings, target.output_path);
            array_append(*cmd_strings, ..flag_string);
        case C_Output_Type.DYNAMIC_LIBRARY;
            // cmd_string = concatenate(COMPILER_STRING_DLL, target.output_path, " ", flag_string, " ");
            array_append(*cmd_strings, ..COMPILER_STRING_DLL);
            array_add(*cmd_strings, target.output_path);
            array_append(*cmd_strings, ..flag_string);
        case C_Output_Type.STATIC_LIBRARY;
            // cmd_string = concatenate(COMPILER_STRING_STATIC, target.output_path, " ", flag_string, " ");
            array_append(*cmd_strings, ..COMPILER_STRING_STATIC);
        case C_Output_Type.COPY_FILE;
            assert(target.dependencies.count == 1);
            in := target.dependencies[0];
            path := C_compiler_build_target(<< in);
            if copy_file(path, target.output_path)
                print("Copied % to %\n", path, target.output_path);
            else
                print("Error copying % to %\n", path, target.output_path);

            return target.output_path;
    }

    flags: [] string;
    if target.output_type == C_Output_Type.DYNAMIC_LIBRARY {
        flags = COMPILER_FLAG_PIC_STRING;
    }
    for target.dependencies {
        array_add(*cmd_strings, C_compiler_build_target(<< it, ..flags));
    }

    for target.libs {
        #if OS_LINUX || OS_MACOSX {
            array_add(*cmd_strings, copy_string("-l"));
            array_add(*cmd_strings, copy_string(it));
        }
    }

    if (cmd_strings.count) {
        cmd_string := concatenate(..cmd_strings, " ");
        print("Running C compiler: %\n", cmd_string);
        success, exit_code, output_string, error_string := os_run_command(..cmd_strings, capture_and_return_output=true);

        if !success || exit_code != 0 {
            if !success {
                print("Could not invoke the command\n");
            }
            print("%\n%\n", output_string, error_string);
            exit(1);
        }

        free(cmd_string);
        // @Leak free each element?
        array_reset(*cmd_strings);
    }

    print("Built %.\n", target.output_path);
    return target.output_path;
}
