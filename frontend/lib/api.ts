// Kleiner API-Client für das Laravel-Backend.

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000/api";

export interface Branding {
  name: string;
  slug: string;
  primary_color: string;
  logo_url: string | null;
  currency: string;
}

export interface Lot {
  id: number;
  name: string;
  address: string | null;
  capacity: number;
  free: number;
  hourly_rate_cents: number;
  free_minutes: number;
  daily_cap_cents: number | null;
}

export interface Session {
  id: number;
  license_plate: string;
  started_at: string;
  ended_at: string | null;
  amount_cents: number | null;
}

// Wir schicken den Tenant immer im Header mit.
async function request<T>(tenant: string, path: string, init: RequestInit = {}, token?: string): Promise<T> {
  const res = await fetch(`${API_URL}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-Tenant": tenant,
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...init.headers,
    },
    cache: "no-store",
  });
  if (!res.ok) {
    // Die Fehlermeldung kommt vom Server (auf Deutsch).
    const body = await res.json().catch(() => ({}));
    throw new Error(body.message ?? `Fehler ${res.status}`);
  }
  return res.json();
}

export const api = {
  branding: (tenant: string) => request<Branding>(tenant, "/branding"),
  lots: (tenant: string) => request<Lot[]>(tenant, "/lots"),
  startSession: (tenant: string, token: string, lotId: number, plate: string) =>
    request<Session>(tenant, "/sessions", {
      method: "POST",
      body: JSON.stringify({ parking_lot_id: lotId, license_plate: plate }),
    }, token),
  stopSession: (tenant: string, token: string, id: number) =>
    request<Session>(tenant, `/sessions/${id}/stop`, { method: "POST" }, token),
};

// Cent -> schöner Preis, z.B. 350 -> "3,50 €".
export function formatMoney(cents: number, currency: string): string {
  return new Intl.NumberFormat("de-DE", { style: "currency", currency }).format(cents / 100);
}
