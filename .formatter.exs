[
  plugins: [Quokka],
  inputs: ["*.{ex,exs}", "{config,lib,test}/**/*.{ex,exs}"],
  quokka: [
    autosort: [:map, :defstruct],
    exclude: [],
    only: [
      :blocks,
      :configs,
      :defs,
      :deprecations,
      :module_directives,
      :pipes,
      :single_node
    ]
  ],
  subdirectories: []
]
