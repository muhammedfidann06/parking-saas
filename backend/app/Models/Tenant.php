<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

// Ein Tenant = ein Kunde der SaaS-Plattform.
class Tenant extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'slug', 'primary_color', 'logo_url', 'currency'];

    public function parkingLots(): HasMany
    {
        return $this->hasMany(ParkingLot::class);
    }

    public function users(): HasMany
    {
        return $this->hasMany(User::class);
    }
}
