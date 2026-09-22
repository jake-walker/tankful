// @ts-check
import { defineConfig } from "astro/config";
import tailwindcss from "@tailwindcss/vite";

import cloudflare from "@astrojs/cloudflare";

// https://astro.build/config
export default defineConfig({
  vite: {
    plugins: [tailwindcss()],
  },

  adapter: cloudflare({
    imageService: {
      build: "compile",
      runtime: "passthrough",
    },
  }),

  redirects: {
    "/ios-beta": "https://testflight.apple.com/join/nJPnQEjj",
    "/android-beta": "https://tally.so/r/5BRKvM",
  },
});
