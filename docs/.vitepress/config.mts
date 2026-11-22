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
				],
			},
			{
				text: "Learn",
				items: [
					{ text: "Mounting your UI", link: "/mounting" },
					{ text: "Utility tags", link: "/utility-tags" },
					{ text: "Tokens", link: "/tokens" },
				],
			},
		],

		socialLinks: [
			{ icon: "github", link: "https://github.com/imavafe/tilly" },
			{ icon: "discord", link: "https://discord.gg/jWESWVMHMj" },
		],
	},
});
