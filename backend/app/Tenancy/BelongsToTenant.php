<?php

namespace App\Tenancy;

use App\Models\Tenant;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Dieses Trait macht ein Model "mandantenfähig".
 *
 * 1) Jede Abfrage sieht nur Daten vom aktuellen Tenant (Global Scope).
 * 2) Neue Einträge bekommen automatisch die richtige tenant_id.
 */
trait BelongsToTenant
{
    protected static function bootBelongsToTenant(): void
    {
        static::addGlobalScope('tenant', function (Builder $query) {
            $tenantId = app(TenantContext::class)->id();
            if ($tenantId !== null) {
                // Wir filtern immer nach dem Tenant. So sieht Kunde A nie die Daten von Kunde B.
                $query->where($query->getModel()->getTable() . '.tenant_id', $tenantId);
            }
        });

        static::creating(function ($model) {
            // Wenn keine tenant_id da ist, nehmen wir den aktuellen Tenant.
            $model->tenant_id ??= app(TenantContext::class)->id();
        });
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }
}
