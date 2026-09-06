# blog
Hosting the sources for my personal blog 

[![Deploy static content to Pages](https://github.com/RiRa12621/blog/actions/workflows/github-pages.yml/badge.svg)](https://github.com/RiRa12621/blog/actions/workflows/github-pages.yml)

## Deployment

The `beautifulhugo` theme requires Hugo `0.146.2` or newer. Deployments are pinned to Hugo `0.163.3`.

For Cloudflare Pages, `wrangler.toml` defines `HUGO_VERSION=0.163.3` for local, Preview, and Production environments.

## SEO

Site-local templates under `layouts/partials/` generate search descriptions, Open Graph/Twitter previews, and Article metadata without changing post text or URLs. Descriptions use an explicit front matter `description`, otherwise the existing article summary, subtitle, or site description. Generated descriptions are plain text capped at 160 characters; search engines may choose a different snippet.

Sharing images use `share_img`, `image`, the first `images` entry, site `images`, or the site logo, in that order. Optional `imageAlt` describes a post's sharing image. Paginated listings have distinct metadata titles and URLs. `robots.txt` advertises Hugo's generated sitemap.

The local `head.html` retains the theme's assets and hooks. When updating Beautiful Hugo, compare it with the theme's `head.html` to carry forward upstream changes.
