import { api } from "@/lib/api";
import { currentTenant } from "@/lib/tenant";
import LotCard from "@/components/LotCard";

// Startseite: Liste der Parkplätze mit freien Plätzen.
export default async function Home() {
  const tenant = await currentTenant();
  const [lots, branding] = await Promise.all([api.lots(tenant), api.branding(tenant)]);

  if (lots.length === 0) {
    return <p>Noch keine Parkplätze.</p>;
  }

  return (
    <section className="grid">
      {lots.map((lot) => (
        <LotCard key={lot.id} lot={lot} tenant={tenant} currency={branding.currency} />
      ))}
    </section>
  );
}
