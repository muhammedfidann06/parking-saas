"use client";

import { useState } from "react";
import { api, formatMoney, Lot, Session } from "@/lib/api";

interface Props {
  lot: Lot;
  tenant: string;
  currency: string;
}

// Eine Karte für einen Parkplatz. Hier kann man parken starten und beenden.
export default function LotCard({ lot, tenant, currency }: Props) {
  const [plate, setPlate] = useState("");
  const [session, setSession] = useState<Session | null>(null);
  const [free, setFree] = useState(lot.free);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  // Das Token speichern wir nach dem Login im Browser (Demo).
  const token = typeof window !== "undefined" ? localStorage.getItem("token") ?? "" : "";

  async function start() {
    setBusy(true);
    setError(null);
    try {
      const s = await api.startSession(tenant, token, lot.id, plate);
      setSession(s);
      setFree((f) => f - 1); // Ein Platz weniger frei.
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(false);
    }
  }

  async function stop() {
    if (!session) return;
    setBusy(true);
    try {
      setSession(await api.stopSession(tenant, token, session.id));
      setFree((f) => f + 1); // Der Platz ist wieder frei.
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(false);
    }
  }

  // Farbe für die Auslastung: grün, gelb oder rot.
  const ratio = free / lot.capacity;
  const status = ratio > 0.3 ? "ok" : ratio > 0 ? "low" : "full";

  return (
    <article className="card">
      <h2>{lot.name}</h2>
      {lot.address && <p className="muted">{lot.address}</p>}
      <p className={`badge ${status}`}>{free} / {lot.capacity} frei</p>
      <p>
        {formatMoney(lot.hourly_rate_cents, currency)} pro Stunde
        {lot.free_minutes > 0 && ` · ${lot.free_minutes} Min. gratis`}
        {lot.daily_cap_cents !== null && ` · max. ${formatMoney(lot.daily_cap_cents, currency)}/Tag`}
      </p>

      {!session || session.ended_at ? (
        <div className="row">
          <input
            value={plate}
            onChange={(e) => setPlate(e.target.value)}
            placeholder="Kennzeichen, z.B. B-AB 123"
            aria-label="Kennzeichen"
          />
          <button onClick={start} disabled={busy || !plate || free === 0}>Parken</button>
        </div>
      ) : (
        <div className="row">
          <span>🚗 {session.license_plate} parkt seit {new Date(session.started_at).toLocaleTimeString("de-DE")}</span>
          <button onClick={stop} disabled={busy}>Beenden</button>
        </div>
      )}

      {session?.ended_at && session.amount_cents !== null && (
        <p className="success">Danke! Preis: {formatMoney(session.amount_cents, currency)}</p>
      )}
      {error && <p className="error">{error}</p>}
    </article>
  );
}
