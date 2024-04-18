import * as ts from "typescript";

interface CompiledOuput {
  jsContents: string;
  jsmapContents: string;
  dtsContents: string;
  dtsmapContents: string;
}

// This provides a utility for turning a string of TypeScript into strings of JS and DTS
// https://github.com/microsoft/TypeScript/wiki/Using-the-Compiler-API#getting-the-dts-from-a-javascript-file
export function tscompile(input: string, appName: string): CompiledOuput {
  const options = {
    ...ts.getDefaultCompilerOptions(),
    declaration: true,
    declarationMap: true,
    sourceMap: true,
    inlineSources: true,
  };
  const inputFileName = `${appName}.ts`;
  const sourceFile = ts.createSourceFile(
    inputFileName,
    input,
    ts.ScriptTarget.ES2020,
  );

  // Create a Program with an in-memory emit
  const createdFiles: Record<string, string> = {};
  const compilerHost: ts.CompilerHost = {
    getSourceFile: (fileName) =>
      fileName === inputFileName ? sourceFile : undefined,
    writeFile: (fileName: string, contents: string) =>
      (createdFiles[fileName] = contents),
    getDefaultLibFileName: () => "lib.d.ts",
    useCaseSensitiveFileNames: () => false,
    getCanonicalFileName: (fileName) => fileName,
    getCurrentDirectory: () => "",
    getNewLine: () => "\n",
    fileExists: (fileName) => fileName === inputFileName,
    readFile: () => "",
    directoryExists: () => true,
    getDirectories: () => [],
  };

  // Prepare and emit the d.ts files
  const program = ts.createProgram([inputFileName], options, compilerHost);
  program.emit();

  return {
    jsContents: createdFiles[`${appName}.js`],
    jsmapContents: createdFiles[`${appName}.js.map`],
    dtsContents: createdFiles[`${appName}.d.ts`],
    dtsmapContents: createdFiles[`${appName}.d.ts.map`],
  };
}
