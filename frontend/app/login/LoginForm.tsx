"use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";
import { api } from "@/lib/api";

// Login-Formular. Das Token speichern wir im Browser.
export default function LoginForm({ tenant }: { tenant: string }) {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const { token } = await api.login(tenant, email, password);
      localStorage.setItem("token", token);
      router.push("/"); // Zurück zur Startseite.
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={submit} className="card" style={{ maxWidth: 360, margin: "0 auto" }}>
      <h2>Anmelden</h2>
      <div className="row">
        <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="E-Mail" aria-label="E-Mail" required />
      </div>
      <div className="row">
        <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="Passwort" aria-label="Passwort" required />
      </div>
      <div className="row">
        <button type="submit" disabled={busy}>{busy ? "…" : "Login"}</button>
      </div>
      {error && <p className="error">{error}</p>}
    </form>
  );
}
