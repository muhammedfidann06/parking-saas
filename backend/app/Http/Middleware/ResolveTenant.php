<?php

namespace App\Http\Middleware;

use App\Models\Tenant;
use App\Tenancy\TenantContext;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Wir finden den Tenant für jeden Request.
 *
 * Reihenfolge:
 *   1) Header "X-Tenant" (gut für die API und für Tests)
 *   2) Subdomain, z.B. "berlin.parking.app" -> "berlin"
 */
class ResolveTenant
{
    public function __construct(private TenantContext $context) {}

    public function handle(Request $request, Closure $next): Response
    {
        $slug = $request->header('X-Tenant') ?? $this->subdomain($request);

        $tenant = $slug ? Tenant::where('slug', $slug)->first() : null;
        if (! $tenant) {
            // Ohne Tenant können wir nichts zeigen.
            return response()->json(['message' => 'Tenant nicht gefunden.'], 404);
        }

        $this->context->set($tenant);

        return $next($request);
    }

    private function subdomain(Request $request): ?string
    {
        $parts = explode('.', $request->getHost());
        // "berlin.parking.app" hat 3 Teile. "localhost" hat nur 1 Teil.
        return count($parts) >= 3 ? $parts[0] : null;
    }
}
