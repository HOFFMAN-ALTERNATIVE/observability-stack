// Captures the provisioned dashboard (CI artifact -> docs/dashboard.png).
import { createRequire } from "node:module";
const require = createRequire(new URL("./package.json", import.meta.url));
const { chromium } = require("playwright");
const base = process.env.GRAFANA ?? "http://127.0.0.1:3000";
const browser = await chromium.launch();
const ctx = await browser.newContext({ viewport: { width: 1600, height: 1000 }, colorScheme: "dark" });
const page = await ctx.newPage();
await page.goto(`${base}/login`);
await page.getByPlaceholder(/email or username/i).fill(process.env.GRAFANA_ADMIN_USER ?? "admin");
await page.getByPlaceholder(/password/i).fill(process.env.GRAFANA_ADMIN_PASSWORD ?? "change-me-please");
await page.getByRole("button", { name: /log in/i }).click();
await page.waitForURL((u) => !u.pathname.startsWith("/login"));
await page.goto(`${base}/d/host-containers?orgId=1&from=now-15m&to=now&kiosk`, { waitUntil: "networkidle" });
await page.waitForTimeout(10000);
await page.screenshot({ path: "docs/dashboard.png" });
await browser.close();
