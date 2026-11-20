import type { CSSProperties, ReactNode } from "react";
import { api } from "@/lib/api";
import { currentTenant } from "@/lib/tenant";
import "./globals.css";

// Server Component: Wir laden das Branding schon auf dem Server.
export async function generateMetadata() {
  const b = await api.branding(await currentTenant());
  return { title: b.name };
}

export default async function RootLayout({ children }: { children: ReactNode }) {
  const branding = await api.branding(await currentTenant());

  return (
    <html lang="de">
      {/* White-Label: Die Hauptfarbe kommt vom Kunden. */}
      <body style={{ "--brand": branding.primary_color } as CSSProperties}>
        <header className="header">
          {branding.logo_url && <img src={branding.logo_url} alt="" height={32} />}
          <h1>{branding.name}</h1>
          <a href="/login" style={{ marginLeft: "auto", color: "#fff" }}>Login</a>
        </header>
        <main className="container">{children}</main>
      </body>
    </html>
  );
}
