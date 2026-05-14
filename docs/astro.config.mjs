// @ts-check
import { defineConfig, fontProviders } from 'astro/config';
import starlight from '@astrojs/starlight';

import mermaid from 'astro-mermaid';
import catppuccin from "@catppuccin/starlight";

// https://astro.build/config
export default defineConfig({
	experimental: {
		fonts: [
			{
				provider: fontProviders.google(),
				name: "Victor Mono",
				cssVariable: "--sl-font",
			},
		],
	},
	integrations: [
		mermaid({
			theme: 'forest',
			autoTheme: true
		}),
		starlight({
			title: 'import-tree',
			sidebar: [
				{
					label: 'import-tree',
					items: [
						{ label: 'Overview', slug: 'overview' },
						{ label: 'Motivation', slug: 'motivation' },
						{ label: 'Community', slug: 'community' },
						{ label: 'Contributing', slug: 'contributing' },
						{ label: 'Sponsor', slug: 'sponsor' },
					],
				},
				{
					label: 'Getting Started',
					items: [
						{ label: 'Quick Start', slug: 'getting-started/quick-start' },
					],
				},
				{
					label: 'Guides',
					items: [
						{ label: 'Filtering Files', slug: 'guides/filtering' },
						{ label: 'Transforming Paths', slug: 'guides/mapping' },
						{ label: 'Custom API', slug: 'guides/custom-api' },
						{ label: 'Combinator Syntax', slug: 'guides/combinator' },
						{ label: 'Outside Modules', slug: 'guides/outside-modules' },
						{ label: 'Dendritic Pattern', slug: 'guides/dendritic' },
					],
				},
				{
					label: 'Reference',
					items: [
						{ label: 'API Reference', slug: 'reference/api' },
						{ label: 'Examples', slug: 'reference/examples' },
					],
				},
			],
			components: {
				Sidebar: './src/components/Sidebar.astro',
				Footer: './src/components/Footer.astro',
				SocialIcons: './src/components/SocialIcons.astro',
				PageSidebar: './src/components/PageSidebar.astro',
			},
			plugins: [
				catppuccin({
					dark: { flavor: "macchiato", accent: "mauve" },
					light: { flavor: "latte", accent: "mauve" },
				}),
			],
			editLink: {
				baseUrl: 'https://github.com/denful/import-tree/edit/main/docs/',
			},
			customCss: [
				'./src/styles/custom.css'
			],
		}),
	],
});
