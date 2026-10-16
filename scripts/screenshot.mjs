// Captures the provisioned dashboard (CI artifact -> docs/dashboard.png).
import { createRequire } from "node:module";
const require = createRequire(new URL("./package.json", import.meta.url));
const { chromium } = require("playwright");
const base = process.env.GRAFANA ?? "http://127.0.0.1:3000";
const browser = await chromium.launch();
const ctx = await browser.newContext({
  viewport: { width: 1600, height: 1000 },
  httpCredentials: {
    username: process.env.GRAFANA_ADMIN_USER ?? "admin",
    password: process.env.GRAFANA_ADMIN_PASSWORD ?? "change-me-please",
  },
});
const page = await ctx.newPage();
await page.goto(`${base}/d/host-containers?orgId=1&from=now-15m&to=now&kiosk`, { waitUntil: "networkidle" });
await page.waitForTimeout(8000);
await page.screenshot({ path: "docs/dashboard.png" });
await browser.close();
