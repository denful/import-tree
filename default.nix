let
  perform =
    {
      pipef ? null,
      initf ? null,
      filterf,
      mapf,
      paths,
      scoped,
      ...
    }:
    path:
    let
      result = if pipef == null then module else pipef (leaves path);

      # module stays a function: callers may apply it as a module function, and
      # keeping it a lambda defers the tree read (`leaves path`) until module-eval
      # rather than at `it ./dir` construction time. It no longer needs `lib` —
      # the reader is pure `builtins` — so the argument is ignored.
      module =
        _:
        let
          files = leaves path;
        in
        {
          imports = if scoped == { } then files else map scoped-import-module files;
        };

      # Like builtins.scopedImport but:
      # - include scope argument in builtins as `builtins.scoped`, for potential reuse in nested invocations
      # - empty `__nixPath` and `builtins.nixPath` (unless explictely set in `scoped` argument)
      scoped-import =
        scoped:
        builtins.scopedImport (
          {
            __nixPath = [ ];
          }
          // scoped
          // {
            builtins =
              scoped.builtins or (
                builtins
                // {
                  nixPath = [ ];
                }
              )
              // {
                inherit scoped;
              };
          }
        );

      scoped-import-module = file: {
        # Let's not lose track of the original file even if scope-imported:
        _file = file;
        imports = [
          (scoped-import scoped file)
        ];
      };

      leaves =
        let
          listFilesRecursive =
            x:
            if isImportTree x then
              x.files
            else if hasOutPath x then
              listFilesRecursive x.outPath
            else if isDirectory x then
              listDirFilesRecursive x
            else
              [ x ];

          nixFilter = andNot (hasInfix "/_") (hasSuffix ".nix");

          initialFilter = if initf != null then initf else nixFilter;

          pathFilter = compose (and filterf initialFilter) toString;

          otherFilter = and filterf (if initf != null then initf else (_: true));

          filter = x: if isPathLike x then pathFilter x else otherFilter x;

          isFileRelative =
            root:
            { file, rel }:
            if file != null && hasPrefix root file then
              {
                file = null;
                rel = removePrefix root file;
              }
            else
              { inherit file rel; };
          getFileRelative = { file, rel }: if rel == null then file else rel;

          # Strip the first matching root-directory prefix from a file, yielding a
          # path relative to that root (or the file itself if none match). Folds the
          # `{ file, rel }` state directly over the roots — once a root matches,
          # `file` becomes null and later roots are no-ops.
          makeRelative =
            roots:
            let
              dirs = builtins.map builtins.toString (builtins.filter isDirectory (flatten roots));
            in
            file:
            getFileRelative (
              builtins.foldl' (acc: root: isFileRelative root acc) {
                file = builtins.toString file;
                rel = null;
              } dirs
            );

          rootRelative =
            roots:
            let
              mkRel = makeRelative roots;
            in
            x: if isPathLike x then mkRel x else x;
        in
        root:
        let
          roots = flatten [
            paths
            root
          ];
          files = flatten (map listFilesRecursive roots);
          relativize = rootRelative [
            paths
            root
          ];
        in
        map mapf (builtins.filter (compose filter relativize) files);

    in
    result;

  # ── utilities vendored from nixpkgs lib (behavior-identical, pure builtins) ──

  # lib.lists.flatten
  flatten = x: if builtins.isList x then builtins.concatMap flatten x else [ x ];

  # lib.strings.hasPrefix
  hasPrefix = pre: s: builtins.substring 0 (builtins.stringLength pre) s == pre;

  # lib.strings.removePrefix
  removePrefix =
    pre: s:
    let
      n = builtins.stringLength pre;
    in
    if builtins.substring 0 n s == pre then builtins.substring n (builtins.stringLength s - n) s else s;

  # lib.strings.hasSuffix
  hasSuffix =
    suffix: content:
    let
      lenSuffix = builtins.stringLength suffix;
      lenContent = builtins.stringLength content;
    in
    lenContent >= lenSuffix && builtins.substring (lenContent - lenSuffix) lenContent content == suffix;

  # lib.strings.hasInfix — literal substring scan (no regex, so no escaping hazard)
  hasInfix =
    infix: content:
    let
      lenInfix = builtins.stringLength infix;
      lenContent = builtins.stringLength content;
      go =
        i:
        if i + lenInfix > lenContent then
          false
        else if builtins.substring i lenInfix content == infix then
          true
        else
          go (i + 1);
    in
    go 0;

  # lib.filesystem.listFilesRecursive
  listDirFilesRecursive =
    dir:
    let
      entries = builtins.readDir dir;
    in
    builtins.concatMap (
      name:
      if entries.${name} == "directory" then
        listDirFilesRecursive (dir + "/${name}")
      else
        [ (dir + "/${name}") ]
    ) (builtins.attrNames entries);

  compose =
    g: f: x:
    g (f x);

  # Applies the second filter first, to allow partial application when building the configuration.
  and =
    g: f: x:
    f x && g x;

  andNot = g: and (x: !(g x));

  matchesRegex = re: p: builtins.match re p != null;

  mapAttr =
    attrs: k: f:
    attrs // { ${k} = f attrs.${k}; };

  isDirectory = and (x: builtins.readFileType x == "directory") isPathLike;

  isPathLike = x: builtins.isPath x || builtins.isString x || hasOutPath x;

  hasOutPath = and (x: x ? outPath) builtins.isAttrs;

  isImportTree = and (x: x ? __config.__functor) builtins.isAttrs;

  inModuleEval = and (x: x ? options) builtins.isAttrs;

  functor =
    self: arg:

    if builtins.isFunction arg && builtins.functionArgs arg == { } then
      arg self # arg is a combinator pass the self import-tree obj
    else if inModuleEval arg then
      perform self.__config [ ] arg
    else
      perform self.__config arg;

  callable =
    let
      initial = {
        # Accumulated configuration
        api = { };
        mapf = (i: i);
        filterf = _: true;
        paths = [ ];
        scoped = { };

        # config is our state (initial at first). this functor allows it
        # to work as if it was a function, taking an update function
        # that will return a new state. for example:
        # in mergeAttrs:  `config (c: c // x)` will merge x into new config.
        __functor =
          config: update:
          let
            # updated is another config
            updated = update config;

            # current is the result of this functor.
            # it is not a config, but an import-tree object containing a __config.
            current = config update;
            boundAPI = builtins.mapAttrs (_: g: g current) updated.api;

            # these two helpers are used to **append** aggregated configs.
            accAttr = attrName: acc: config (c: mapAttr (update c) attrName acc);
            mergeAttrs = attrs: config (c: (update c) // attrs);
          in
          boundAPI
          // {
            __config = updated;
            __functor = functor; # user-facing callable

            # Configuration updates (accumulating)
            filter = filterf: accAttr "filterf" (and filterf);
            filterNot = filterf: accAttr "filterf" (andNot filterf);
            match = regex: accAttr "filterf" (and (matchesRegex regex));
            matchNot = regex: accAttr "filterf" (andNot (matchesRegex regex));
            map = mapf: accAttr "mapf" (compose mapf);
            addScoped = attrs: accAttr "scoped" (s: s // attrs);
            addPath = path: accAttr "paths" (p: p ++ [ path ]);
            addAPI = api: accAttr "api" (a: a // api);

            # Configuration updates (non-accumulating)
            # withLib is retained as a no-op for backward compatibility: the tree
            # reader no longer needs nixpkgs lib, so any passed lib is ignored.
            withLib = _lib: mergeAttrs { };
            initFilter = initf: mergeAttrs { inherit initf; };
            pipeTo = pipef: mergeAttrs { inherit pipef; };
            leaves = mergeAttrs { pipef = (i: i); };
            leafs =
              builtins.warn "import-tree.leafs has been deprecated. Use import-tree.leaves instead."
                (mergeAttrs {
                  pipef = (i: i);
                });

            # Applies empty (for already path-configured trees)
            result = current [ ];

            # Return a list of all filtered files.
            files = current.leaves.result;

            # returns the original empty state
            new = callable;
          };
      };
    in
    initial (config: config);

in
callable
