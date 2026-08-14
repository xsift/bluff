import { expect, test, type Page } from "@playwright/test";

async function finishGame(page: Page) {
  await page.getByRole("button", { name: "开始一局" }).click();
  const input = page.getByLabel("输入内容");
  await expect(input).toBeVisible();
  await input.fill("它常在生活里出现");
  await expect(input).toHaveValue("它常在生活里出现");
  await page.getByRole("button", { name: "提交描述" }).click();
  await expect(page.getByRole("button", { name: "提问" })).toBeVisible();

  await input.fill("请分享一种感受");
  await expect(input).toHaveValue("请分享一种感受");
  await page.getByRole("button", { name: "提问" }).click();
  await expect(page.getByRole("button", { name: "提交回答" })).toBeVisible();

  await input.fill("我会偶尔主动接触它");
  await expect(input).toHaveValue("我会偶尔主动接触它");
  await page.getByRole("button", { name: "提交回答" }).click();
  await expect(page.locator(".chat li")).toHaveCount(11);

  await input.fill("我觉得它很常见");
  await expect(input).toHaveValue("我觉得它很常见");
  await page.getByRole("button", { name: "提交回答" }).click();
  await expect(page.getByRole("button", { name: "确认投票" })).toBeVisible();
  await page.getByRole("button", { name: "确认投票" }).click();
  await expect(page.getByRole("heading", { name: /获胜/ })).toBeVisible();
  await expect(page.getByText("答案已揭晓")).toBeVisible();
}

test("a player can finish a rule-bot game", async ({ page }) => {
  await page.goto("/");
  await finishGame(page);
  await page.reload();
  await expect(page.getByRole("heading", { name: "最近十局" })).toBeVisible();
});

test("a player can finish a complete game at phone width", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/");
  await finishGame(page);
});
