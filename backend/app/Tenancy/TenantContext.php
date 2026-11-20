<?php

namespace App\Tenancy;

use App\Models\Tenant;

/**
 * Hier speichern wir den aktuellen Tenant für einen Request.
 * Der Service ist ein Singleton (siehe AppServiceProvider).
 */
class TenantContext
{
    private ?Tenant $tenant = null;

    public function set(Tenant $tenant): void
    {
        $this->tenant = $tenant;
    }

    public function get(): ?Tenant
    {
        return $this->tenant;
    }

    public function id(): ?int
    {
        return $this->tenant?->id;
    }
}
