import js from "@eslint/js";
import globals from "globals";

const eslintConfig = [
  js.configs.recommended,

  // App source files — warn on unused vars (existing code has intentional imports)
  {
    files: [
      "app/**/*.{js,jsx}",
      "components/**/*.{js,jsx}",
      "contexts/**/*.{js,jsx}",
      "lib/**/*.{js,jsx}",
      "e2e/**/*.{js,jsx}",
    ],
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node,
      },
      parserOptions: {
        ecmaFeatures: { jsx: true },
      },
    },
    rules: {
      "no-unused-vars": "off",
      "prefer-const": "error",
      "no-var": "error",
      eqeqeq: ["error", "always"],
    },
  },

  // Test files — jest + browser globals
  {
    files: [
      "__tests__/**/*.{js,jsx}",
      "**/*.test.{js,jsx}",
      "**/*.spec.{js,jsx}",
    ],
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node,
        ...globals.jest,
      },
      parserOptions: {
        ecmaFeatures: { jsx: true },
      },
    },
    rules: {
      "no-unused-vars": "off",
      "prefer-const": "error",
      "no-var": "error",
    },
  },

  // Mock files — CommonJS globals
  {
    files: ["__mocks__/**/*.js"],
    languageOptions: {
      globals: {
        ...globals.commonjs,
      },
    },
  },

  {
    ignores: [
      ".next/**",
      "node_modules/**",
      "coverage/**",
      "babel.config.js",
      "jest.setup.js",
      "playwright.config.js",
      "next.config.mjs",
      "postcss.config.mjs",
      "tailwind.config.js",
    ],
  },
];

export default eslintConfig;