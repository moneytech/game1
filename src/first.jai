
#import "Basic";
#import "Compiler";
#import "File";

setup_build_options :: () -> Build_Options {
    options := get_build_options();
    set_optimization_level(*options, 0, 0);
    options.backend = Backend.LLVM;
    options.llvm_options.enable_split_modules = false;

    options.output_type = Build_Output_Type.NO_OUTPUT;
    options.output_executable_name = "";
    options.output_path = concatenate(#filepath, "../run_tree/");
    make_directory_if_it_does_not_exist(options.output_path);
    
    set_build_options(options);
    return options;
};

build_workspace :: (name: string) -> Workspace, Build_Options {
    options := setup_build_options_for_demo();
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
    return w, options;
}
