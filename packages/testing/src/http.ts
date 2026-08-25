/**
 * A tiny polling helper for smoke lanes.
 *
 * `docker compose --wait` reports container health, not application readiness;
 * a service can be "healthy" to Docker and still be constructing its clients.
 * Polling the real readiness endpoint is what closes that gap.
 */
export async function waitForOk(
  url: string,
  options: { timeoutMs?: number; intervalMs?: number } = {}
): Promise<void> {
  const timeoutMs = options.timeoutMs ?? 60_000;
  const intervalMs = options.intervalMs ?? 500;
  const deadline = Date.now() + timeoutMs;
  let lastError = "no attempt made";

  while (Date.now() < deadline) {
    try {
      const res = await fetch(url);
      if (res.ok) return;
      lastError = `HTTP ${res.status}`;
    } catch (err) {
      lastError = err instanceof Error ? err.message : String(err);
    }
    await new Promise((resolve) => setTimeout(resolve, intervalMs));
  }

  throw new Error(`waitForOk: ${url} did not become ready in ${timeoutMs}ms (last: ${lastError})`);
}
