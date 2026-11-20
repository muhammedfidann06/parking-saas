<?php

namespace App\Models;

use App\Tenancy\BelongsToTenant;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

// Eine Parkzeit: von "started_at" bis "ended_at".
class ParkingSession extends Model
{
    use HasFactory, BelongsToTenant;

    protected $fillable = ['parking_lot_id', 'user_id', 'license_plate', 'started_at', 'ended_at', 'amount_cents'];

    protected $casts = [
        'started_at' => 'datetime',
        'ended_at' => 'datetime',
    ];

    public function lot(): BelongsTo
    {
        return $this->belongsTo(ParkingLot::class, 'parking_lot_id');
    }

    public function isActive(): bool
    {
        return $this->ended_at === null;
    }
}
