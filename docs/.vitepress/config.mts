import { defineConfig } from "vitepress";

// https://vitepress.dev/reference/site-config
export default defineConfig({
	title: "Tilly",
	description: "Tailwind for Roblox",
	base: "/tilly/",
	themeConfig: {
		// https://vitepress.dev/reference/default-theme-config
		nav: [{ text: "Home", link: "/" }],

		sidebar: [
			{
				text: "Intro",
				items: [
					{ text: "How it works", link: "/explainer" },
					{ text: "Get started", link: "/start" },
					{ text: "For your framework", link: "/setups" },
				],
			},
			{
				text: "Usage",
				items: [
					{ text: "Placeholder", link: "/explainer" },
				],
			},
		],

		socialLinks: [
			{ icon: "github", link: "https://github.com/vuejs/vitepress" },
		],
	},
});
