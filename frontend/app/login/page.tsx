import { currentTenant } from "@/lib/tenant";
import LoginForm from "./LoginForm";

// Server Component: Wir lesen den Tenant und geben ihn an das Formular.
export default async function LoginPage() {
  return <LoginForm tenant={await currentTenant()} />;
}
