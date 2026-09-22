# Tankful website

A small static Astro site styled with Tailwind CSS. No client-side JavaScript,
external fonts, analytics, or cookies are added by the site.

## Editing

- `src/pages/index.astro`: landing page copy and screenshot list. Put images in
  `public/screenshots/`, then set each `src` to `/screenshots/your-file.png`.
  Update the labels to describe your screenshots.
- `src/pages/privacy-policy.md`: privacy copy and update date. The old `/privacy/`
  address redirects here.
- `src/layouts/main.astro`: shared metadata and footer.
- `src/styles/main.css`: brand colour and theme values.
  Dark mode follows the device setting through `prefers-color-scheme`; edit the
  dark colour overrides here. Markdown uses Tailwind's `dark:prose-invert`.
- `public/fuel-symbol.png`: symbol copied from the iOS icon source. The landing
  page uses a flat orange background until a finished iOS icon is exported.
  Replace the icon markup in `index.astro` with that exported image when ready.

Set `signupUrl` near the top of `index.astro` to show the beta signup link.
The link stays hidden while the URL is empty.
Screenshot placeholders are clearly labelled and can also be removed entirely.
They form a centred vertical stack on small screens and a three-column row from 640px.

## Commands

Run from `website/` with Node 22.12+ and pnpm:

- `pnpm dev`: development server (reuse the existing server if running).
- `pnpm build`: production output in `dist/`.
- `pnpm preview`: preview the production build.
