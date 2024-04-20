// @ts-check

import eslint from "@eslint/js";
import tseslint from "typescript-eslint";
import eslintConfigPrettier from "eslint-config-prettier";
import stylistic from "@stylistic/eslint-plugin";

export default tseslint.config(
  eslint.configs.recommended,
  ...tseslint.configs.recommended,
  {
    languageOptions: {
      parserOptions: {
        sourceType: "module",
        ecmaVersion: 2020,
        project: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
    plugins: {
      "@stylistic": stylistic,
    },
    ignores: [".openzeppelin/", "artifacts/", "cache/", "subgraph"],
    rules: {
      "@stylistic/indent": ["error", 2],
      "@stylistic/array-bracket-spacing": ["error", "never"],
      "@stylistic/eol-last": ["error", "always"],
      "@stylistic/comma-style": ["error", "last"],
      // "@stylistic/comma-dangle": [
      //   "error",
      //   {
      //     arrays: "never",
      //     objects: "always",
      //     imports: "never",
      //     exports: "never",
      //     functions: "always",
      //   },
      // ],
      "@stylistic/quotes": ["error", "double"],
    },
  },
  eslintConfigPrettier
);
