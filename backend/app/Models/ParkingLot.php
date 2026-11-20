<?php

namespace App\Models;

use App\Tenancy\BelongsToTenant;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ParkingLot extends Model
{
    use HasFactory, BelongsToTenant;

    protected $fillable = [
        'name', 'address', 'capacity',
        'hourly_rate_cents', 'free_minutes', 'daily_cap_cents',
    ];

    public function sessions(): HasMany
    {
        return $this->hasMany(ParkingSession::class);
    }

    // Wie viele Plätze sind noch frei?
    public function freeSpots(): int
    {
        $occupied = $this->sessions()->whereNull('ended_at')->count();

        return max(0, $this->capacity - $occupied);
    }
}
