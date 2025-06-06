{ lib }:
let
  # Helper function to check if a file has allowed extension
  hasAllowedExtension = name: extensions: lib.any (ext: lib.hasSuffix ext name) extensions;

  # Helper to check if file should be excluded
  isNotExcluded = name: exclude: !(lib.elem name exclude);

  # Get all files from directory (fixed recursive logic)
  getFiles =
    dir: extensions: recursive: exclude:
    let
      dirContents = builtins.readDir dir;
      handleEntry =
        name: type:
        if type == "regular" && hasAllowedExtension name extensions && isNotExcluded name exclude then
          [ (dir + "/${name}") ]
        else if type == "directory" && recursive then # Fixed: use recursive parameter
          getFiles (dir + "/${name}") extensions recursive exclude
        else
          [ ];
    in
    lib.concatLists (lib.mapAttrsToList handleEntry dirContents);

  readYamlsFromDir =
    {
      dir,
      extensions ? [
        ".yaml"
        ".yml"
      ],
      recursive ? false,
      exclude ? [ ],
    }:
    let
      matchingFiles = getFiles dir extensions recursive exclude;
      # Sort files for deterministic order
      sortedFiles = lib.sort (a: b: toString a < toString b) matchingFiles;
      yamlContents = map builtins.readFile sortedFiles;
    in
    yamlContents;
in
readYamlsFromDir
