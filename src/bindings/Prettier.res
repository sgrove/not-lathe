type parser

@module("prettier")
external format: (string, {..}) => string = "format"

@module("prettier/parser-babel") external babel: parser = "default"
