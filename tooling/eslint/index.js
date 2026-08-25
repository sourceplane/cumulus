// @ts-check
import tsPlugin from "@typescript-eslint/eslint-plugin";
import tsParser from "@typescript-eslint/parser";

/** @type {import('eslint').Linter.FlatConfig[]} */
const config = [
  {
    files: ["**/*.ts", "**/*.tsx"],
    plugins: {
      "@typescript-eslint": tsPlugin,
    },
    languageOptions: {
      parser: tsParser,
      parserOptions: {
        ecmaVersion: 2022,
        sourceType: "module",
      },
    },
    rules: {
      "@typescript-eslint/no-unused-vars": ["error", { argsIgnorePattern: "^_" }],
      "@typescript-eslint/no-explicit-any": "warn",
      // console.log in a container is an unstructured line in the middle of
      // structured JSON logs — it survives to production and cannot be queried.
      // warn/error are allowed as last-resort channels.
      "no-console": ["warn", { allow: ["warn", "error"] }],
      // A hardcoded AWS account id or ARN in application code is an
      // instantiation blocker: it makes the repo un-forkable into a second
      // account. Resource coordinates arrive through configuration, published
      // by the component that provisioned them.
      "no-restricted-syntax": [
        "error",
        {
          selector: "Literal[value=/^arn:aws:/]",
          message:
            "Don't hardcode an AWS ARN. Resource coordinates arrive through configuration, published by the terraform component that created them.",
        },
        {
          selector: "Literal[value=/^[0-9]{12}$/]",
          message:
            "This looks like an AWS account id. Account-specific values must come from configuration, never from source.",
        },
      ],
    },
  },
  {
    ignores: ["dist/**", "coverage/**", "*.tsbuildinfo"],
  },
];

export default config;
