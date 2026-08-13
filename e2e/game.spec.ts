import { expect, test } from "@playwright/test";
test("a player can finish a rule-bot game", async ({ page }) => {
  await page.goto("/"); await page.getByRole("button", { name: "开始一局" }).click();
  await page.getByLabel("输入内容").fill("它常在生活里出现"); await page.getByRole("button", { name: "提交描述" }).click();
  await expect(page.getByRole("button", { name: "提问" })).toBeVisible();
  await page.getByLabel("输入内容").fill("它通常在哪里出现？"); await page.getByRole("button", { name: "提问" }).click();
  await expect(page.getByRole("button", { name: "提交回答" })).toBeVisible();
  await page.getByLabel("输入内容").fill("我会偶尔主动接触它"); await page.getByRole("button", { name: "提交回答" }).click();
  await expect(page.locator(".chat li")).toHaveCount(11);
  await page.getByLabel("输入内容").fill("我觉得它很常见"); await page.getByRole("button", { name: "提交回答" }).click();
  await expect(page.getByRole("button", { name: "确认投票" })).toBeVisible(); await page.getByRole("button", { name: "确认投票" }).click();
  await expect(page.getByRole("heading", { name: /获胜/ })).toBeVisible();
});
test("works at phone width", async ({ page }) => { await page.setViewportSize({ width: 390, height: 844 }); await page.goto("/"); await page.getByRole("button", { name: "开始一局" }).click(); await expect(page.getByText("你的私密信息")).toBeVisible(); });
