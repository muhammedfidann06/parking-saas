<?php

use App\Http\Controllers\Api\BrandingController;
use App\Http\Controllers\Api\ParkingLotController;
use App\Http\Controllers\Api\ParkingSessionController;
use App\Http\Middleware\EnsureUserBelongsToTenant;
use App\Http\Middleware\ResolveTenant;
use Illuminate\Support\Facades\Route;

// Alle Routen brauchen einen Tenant.
Route::middleware(ResolveTenant::class)->group(function () {
    // Öffentlich: Branding und Parkplätze ansehen.
    Route::get('/branding', BrandingController::class);
    Route::get('/lots', [ParkingLotController::class, 'index']);

    // Mit Login (Laravel Sanctum). Danach prüfen wir den Tenant vom Benutzer.
    // Wichtig: Wir benutzen {id} statt Route-Model-Binding. So läuft die Suche
    // erst NACH ResolveTenant, und der Tenant-Filter ist sicher aktiv.
    Route::middleware(['auth:sanctum', EnsureUserBelongsToTenant::class])->group(function () {
        Route::post('/lots', [ParkingLotController::class, 'store']);
        Route::post('/sessions', [ParkingSessionController::class, 'start']);
        Route::post('/sessions/{id}/stop', [ParkingSessionController::class, 'stop'])->whereNumber('id');
        Route::get('/sessions/{id}/quote', [ParkingSessionController::class, 'quote'])->whereNumber('id');
    });
});
