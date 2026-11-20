import { headers } from "next/headers";

// Wir lesen den Tenant aus der Subdomain: "berlin.parking.app" -> "berlin".
// Lokal (localhost) nehmen wir den Wert aus der .env-Datei.
export async function currentTenant(): Promise<string> {
  const host = (await headers()).get("host") ?? "";
  const parts = host.split(":")[0].split(".");
  if (parts.length >= 3) return parts[0];
  return process.env.NEXT_PUBLIC_DEFAULT_TENANT ?? "berlin";
}
