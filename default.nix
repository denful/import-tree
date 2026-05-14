let
  perform =
    {
      lib ? null,
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
      result =
        if pipef == null then
          { imports = [ module ]; }
        else if lib == null then
          throw "You need to call withLib before trying to read the tree."
        else
          pipef (leafs lib path);

      # module exists so we delay access to lib til we are part of the module system.
      module =
        { lib, ... }:
        let
          files = leafs lib path;
          imports = if scoped == { } then files else map scoped-import files;
        in
        {
          inherit imports;
        };

      scoped-import = builtins.scopedImport (
        {
          inherit builtins;
          __nixPath = [ ];
        }
        // scoped
      );

      leafs =
        lib:
        let
          treeFiles = t: (t.withLib lib).files;

          listFilesRecursive =
            x:
            if isImportTree x then
              treeFiles x
            else if hasOutPath x then
              listFilesRecursive x.outPath
            else if isDirectory x then
              lib.filesystem.listFilesRecursive x
            else
              [ x ];

          nixFilter = andNot (lib.hasInfix "/_") (lib.hasSuffix ".nix");

          initialFilter = if initf != null then initf else nixFilter;

          pathFilter = compose (and filterf initialFilter) toString;

          otherFilter = and filterf (if initf != null then initf else (_: true));

          filter = x: if isPathLike x then pathFilter x else otherFilter x;

          isFileRelative =
            root:
            { file, rel }:
            if file != null && lib.hasPrefix root file then
              {
                file = null;
                rel = lib.removePrefix root file;
              }
            else
              { inherit file rel; };
          getFileRelative = { file, rel }: if rel == null then file else rel;

          makeRelative =
            roots:
            lib.pipe roots [
              (lib.lists.flatten)
              (builtins.filter isDirectory)
              (builtins.map builtins.toString)
              (builtins.map isFileRelative)
              (fx: fx ++ [ getFileRelative ])
              (
                fx: file:
                lib.pipe {
                  file = builtins.toString file;
                  rel = null;
                } fx
              )
            ];

          rootRelative =
            roots:
            let
              mkRel = makeRelative roots;
            in
            x: if isPathLike x then mkRel x else x;
        in
        root:
        lib.pipe
          [ paths root ]
          [
            (lib.lists.flatten)
            (map listFilesRecursive)
            (lib.lists.flatten)
            (builtins.filter (
              compose filter (rootRelative [
                paths
                root
              ])
            ))
            (map mapf)
          ];

    in
    result;

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
    else
      perform self.__config (if inModuleEval arg then [ ] else arg);

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
            withLib = lib: mergeAttrs { inherit lib; };
            initFilter = initf: mergeAttrs { inherit initf; };
            pipeTo = pipef: mergeAttrs { inherit pipef; };
            leafs = mergeAttrs { pipef = (i: i); };

            # Applies empty (for already path-configured trees)
            result = current [ ];

            # Return a list of all filtered files.
            files = current.leafs.result;

            # returns the original empty state
            new = callable;
          };
      };
    in
    initial (config: config);

in
callable
