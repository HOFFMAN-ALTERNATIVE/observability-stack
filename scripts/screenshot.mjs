// Captures the provisioned dashboard (used in CI to produce docs/dashboard.png).
import { chromium } from "playwright";
const base = process.env.GRAFANA ?? "http://127.0.0.1:3000";
const user = process.env.GRAFANA_ADMIN_USER ?? "admin";
const pass = process.env.GRAFANA_ADMIN_PASSWORD ?? "change-me-please";
const browser = await chromium.launch();
const ctx = await browser.newContext({
  viewport: { width: 1600, height: 1000 },
  httpCredentials: { username: user, password: pass },
});
const page = await ctx.newPage();
await page.goto(`${base}/d/host-containers?orgId=1&from=now-15m&to=now&kiosk`, { waitUntil: "networkidle" });
await page.waitForTimeout(5000);
await page.screenshot({ path: "docs/dashboard.png" });
await browser.close();
